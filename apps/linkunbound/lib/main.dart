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

  if (await _tryDelegate(url)) exit(0);

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
    await _firstBoot(
      browserService,
      iconExtractor,
      iconsDir,
      registrationService,
    );
  }

  await ruleService.load();

  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(titleBarStyle: TitleBarStyle.hidden, size: Size(1, 1)),
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
      localeFileProvider.overrideWithValue(File('${appDataDir.path}\\locale')),
      edgeWarningFileProvider.overrideWithValue(
        File('${appDataDir.path}\\edge_warning_dismissed'),
      ),
    ],
  );

  container.read(updateInfoProvider);

  container.listen<AppState>(appStateProvider, (prev, next) async {
    if (prev?.mode == next.mode) return;
    switch (next.mode) {
      case AppMode.hidden:
        await windowManager.hide();
      case AppMode.settings:
        await windowManager.setSize(const Size(580, 700));
        await windowManager.center();
        await windowManager.setSkipTaskbar(false);
        await windowManager.setAlwaysOnTop(false);
        await windowManager.show();
        await windowManager.focus();
      case AppMode.picker:
        final browsers = container.read(browsersProvider);
        final winSize = PickerLayout.windowSize(browsers.length);
        final (cursorX, cursorY) = WinInstance.getCursorPosition();
        final (screenW, screenH) = WinInstance.getScreenSize();
        final x = (cursorX - winSize.width / 2).clamp(
          8.0,
          screenW - winSize.width - 8,
        );
        final y = (cursorY + 16).clamp(8.0, screenH - winSize.height - 8);
        _log.info(
          'Picker: ${browsers.length} browsers, '
          'window=${winSize.width.toInt()}x${winSize.height.toInt()}, '
          'pos=(${x.toInt()}, ${y.toInt()})',
        );
        await windowManager.setSize(winSize);
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
    UncontrolledProviderScope(container: container, child: const NavigateApp()),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isFirstBoot) {
      container.read(appStateProvider.notifier).showSettings();
    } else if (url != null) {
      _handleUrl(url, container);
    }
  });
}

Future<bool> _tryDelegate(String? url) async {
  final client = WinPipeClient();
  final message = url != null
      ? OpenUrlMessage(url)
      : const ShowSettingsMessage();
  WinInstance.allowForeground();

  if (await client.send(message)) {
    _log.info('Delegated to existing instance, exiting');
    return true;
  }
  return false;
}

Future<void> _firstBoot(
  BrowserService browserService,
  IconExtractor iconExtractor,
  Directory iconsDir,
  RegistrationService registrationService,
) async {
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

void _handleUrl(String url, ProviderContainer container) {
  final resolved = _unwrapSafeLink(url);
  final ruleService = container.read(ruleServiceProvider);
  final matchedBrowserId = ruleService.lookupBrowser(resolved);

  if (matchedBrowserId != null) {
    final browsers = container.read(browserServiceProvider).browsers;
    final browser = browsers.where((b) => b.id == matchedBrowserId).firstOrNull;
    if (browser != null) {
      _log.info('Rule match: $resolved → ${browser.name}');
      container
          .read(launchServiceProvider)
          .launch(browser.executablePath, resolved, browser.extraArgs);
      return;
    }
  }

  container.read(appStateProvider.notifier).showPicker(resolved);
}

String? _extractUrl(List<String> args) {
  for (final arg in args) {
    final resolved = stripEdgeProtocol(arg);
    final uri = Uri.tryParse(resolved);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return _unwrapSafeLink(resolved);
    }
  }
  return null;
}

String _unwrapSafeLink(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null) return raw;

  final host = uri.host.toLowerCase();
  final isSafeLink =
      host.endsWith('.safelinks.protection.outlook.com') ||
      host == 'statics.teams.cdn.office.net';
  if (!isSafeLink) return raw;

  final inner = uri.queryParameters['url'];
  if (inner != null && inner.isNotEmpty) {
    final decoded = Uri.decodeFull(inner);
    final innerUri = Uri.tryParse(decoded);
    if (innerUri != null &&
        (innerUri.scheme == 'http' || innerUri.scheme == 'https')) {
      _log.info('Unwrapped SafeLink: $decoded');
      return decoded;
    }
  }

  return raw;
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
