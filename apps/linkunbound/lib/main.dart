import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'platform/windows/win_browser_detector.dart';
import 'platform/windows/win_icon_extractor.dart';
import 'platform/windows/win_instance.dart';
import 'platform/windows/win_launch_service.dart';
import 'platform/windows/win_pipe_server.dart';
import 'platform/windows/win_registration_service.dart';
import 'platform/windows/win_startup_service.dart';
import 'providers.dart';
import 'ui/picker/picker_layout.dart';

final _log = Logger('Main');

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDataDir = Directory(
    '${Platform.environment['APPDATA']}\\LinkUnbound',
  );
  final browsersFile = File('${appDataDir.path}\\browsers.json');
  final rulesFile = File('${appDataDir.path}\\rules.json');
  final logFile = File('${appDataDir.path}\\navigate.log');
  final iconsDir = Directory('${appDataDir.path}\\icons');

  await appDataDir.create(recursive: true);
  initLogging(logFile);

  final url = _extractUrl(args);
  _log.info('Started with args: $args, extracted URL: $url');

  final client = WinPipeClient();
  final delegateMessage =
      url != null ? OpenUrlMessage(url) : const ShowSettingsMessage();
  WinInstance.allowForeground();

  if (await client.send(delegateMessage)) {
    _log.info('Delegated to existing instance, exiting');
    exit(0);
  }

  final instance = WinInstance();
  if (!instance.acquire()) {
    _log.warning('Mutex held but pipe unreachable — exiting');
    exit(0);
  }

  final browserDetector = WinBrowserDetector();
  final iconExtractor = WinIconExtractor();
  final browserService = BrowserService(
    configFile: browsersFile,
    browserDetector: browserDetector,
  );
  final ruleService = RuleService(rulesFile: rulesFile);
  final registrationService = WinRegistrationService();
  final startupService = WinStartupService();
  final launchService = WinLaunchService();

  final pipeServer = WinPipeServer();
  try {
    await pipeServer.start();
  } on Exception catch (e) {
    _log.warning('Pipe server failed to start: $e');
  }

  final isFirstBoot = !browsersFile.existsSync();
  await browserService.load();

  if (isFirstBoot) {
    await browserService.scanAndMerge();
    await iconsDir.create(recursive: true);
    for (final browser in browserService.browsers) {
      try {
        final outputPath = '${iconsDir.path}\\${browser.id}.png';
        await iconExtractor.extractIcon(browser.executablePath, outputPath);
      } on Exception catch (e) {
        _log.warning('Icon extraction failed for ${browser.name}: $e');
      }
    }
    await registrationService.register(Platform.resolvedExecutable);
    _log.info(
      'First boot: scanned ${browserService.browsers.length} browsers, registered',
    );
  }

  await ruleService.load();

  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      size: Size(1, 1),
    ),
    () async {
      await windowManager.hide();
    },
  );

  final container = ProviderContainer(
    overrides: [
      browserServiceProvider.overrideWithValue(browserService),
      ruleServiceProvider.overrideWithValue(ruleService),
      registrationServiceProvider.overrideWithValue(registrationService),
      startupServiceProvider.overrideWithValue(startupService),
      iconExtractorProvider.overrideWithValue(iconExtractor),
      iconsDirProvider.overrideWithValue(iconsDir),
      launchServiceProvider.overrideWithValue(launchService),
    ],
  );

  container.listen<AppState>(appStateProvider, (prev, next) async {
    if (prev?.mode == next.mode) return;
    switch (next.mode) {
      case AppMode.hidden:
        await windowManager.hide();
      case AppMode.settings:
        await windowManager.setSize(const Size(800, 600));
        await windowManager.center();
        await windowManager.setSkipTaskbar(false);
        await windowManager.setAlwaysOnTop(false);
        await windowManager.show();
        await windowManager.focus();
      case AppMode.picker:
        final browsers = container.read(browsersProvider);
        final (columns, rows) = PickerLayout.grid(browsers.length);
        final gridWidth = columns * 88.0 + (columns > 1 ? (columns - 1) * 8.0 : 0);
        final pickerWidth = (gridWidth + 48.0).clamp(340.0, 600.0);
        final pickerHeight = 140.0 + rows * 88.0 + (rows > 1 ? (rows - 1) * 8.0 : 0);
        await windowManager.setSize(Size(pickerWidth, pickerHeight));
        final (cursorX, cursorY) = WinInstance.getCursorPosition();
        final (screenW, screenH) = WinInstance.getScreenSize();
        final x = (cursorX - pickerWidth / 2).clamp(8.0, screenW - pickerWidth - 8);
        final y = (cursorY + 16).clamp(8.0, screenH - pickerHeight - 8);
        await windowManager.setPosition(Offset(x, y));
        await windowManager.setSkipTaskbar(true);
        await windowManager.setAlwaysOnTop(true);
        await windowManager.show();
        await windowManager.focus();
    }
  });

  pipeServer.messages.listen((message) {
    switch (message) {
      case OpenUrlMessage(:final url):
        _log.info('Pipe received: open_url $url');
        _handleUrl(url, container);
      case ShowSettingsMessage():
        _log.info('Pipe received: show_settings');
        container.read(appStateProvider.notifier).showSettings();
      case PingMessage():
        _log.fine('Pipe received: ping');
    }
  });

  await _initTray(container, instance, pipeServer);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NavigateApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isFirstBoot) {
      container.read(appStateProvider.notifier).showSettings();
    } else if (url != null) {
      _handleUrl(url, container);
    }
  });
}

void _handleUrl(String url, ProviderContainer container) {
  final ruleService = container.read(ruleServiceProvider);
  final matchedBrowserId = ruleService.lookupBrowser(url);

  if (matchedBrowserId != null) {
    final browsers = container.read(browserServiceProvider).browsers;
    final browser = browsers.where((b) => b.id == matchedBrowserId).firstOrNull;
    if (browser != null) {
      _log.info('Rule match: $url → ${browser.name}');
      container.read(launchServiceProvider).launch(
            browser.executablePath,
            url,
            browser.extraArgs,
          );
      return;
    }
  }

  container.read(appStateProvider.notifier).showPicker(url);
}

String? _extractUrl(List<String> args) {
  for (final arg in args) {
    final uri = Uri.tryParse(arg);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return arg;
    }
  }
  return null;
}

Future<void> _initTray(
  ProviderContainer container,
  WinInstance instance,
  WinPipeServer pipeServer,
) async {
  final tray = SystemTray();
  await tray.initSystemTray(
    title: 'LinkUnbound',
    iconPath: 'assets/app_icon.ico',
    toolTip: 'LinkUnbound — Browser Picker',
  );

  final menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(
      label: 'Settings',
      onClicked: (_) =>
          container.read(appStateProvider.notifier).showSettings(),
    ),
    MenuSeparator(),
    MenuItemLabel(
      label: 'Exit',
      onClicked: (_) async {
        await pipeServer.stop();
        instance.release();
        exit(0);
      },
    ),
  ]);
  await tray.setContextMenu(menu);

  tray.registerSystemTrayEventHandler((eventName) {
    switch (eventName) {
      case kSystemTrayEventDoubleClick:
        container.read(appStateProvider.notifier).showSettings();
      case kSystemTrayEventRightClick:
        tray.popUpContextMenu();
    }
  });
}
