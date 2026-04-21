import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:logging/logging.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'platform/platform_bindings.dart';
import 'platform/tray_controller.dart';
import 'providers.dart';
import 'ui/picker/picker_layout.dart';

final _log = Logger('Bootstrap');

Future<void> bootstrap(PlatformBindings bindings, List<String> args) async {
  initLogging(bindings.logFile);

  _log.info('Started with args: $args');

  if (await bindings.tryDelegate(bindings.initialEvent)) {
    exit(0);
  }

  if (!await bindings.claim()) {
    exit(0);
  }

  final browserService = BrowserService(
    configFile: bindings.browsersFile,
    browserDetector: bindings.browserDetector,
  );
  final ruleService = RuleService(rulesFile: bindings.rulesFile);

  final isFirstBoot = !bindings.browsersFile.existsSync();
  await browserService.load();

  if (isFirstBoot) {
    await _firstBoot(
      browserService: browserService,
      iconExtractor: bindings.iconExtractor,
      iconsDir: bindings.iconsDir,
      registrationService: bindings.registrationService,
      executablePath: bindings.executablePath,
    );
  }

  await ruleService.load();

  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      size: Size(640, 700),
      center: false,
    ),
    () async {
      await windowManager.setPosition(const Offset(-9999, -9999));
      await windowManager.setSkipTaskbar(true);
    },
  );

  final container = ProviderContainer(
    overrides: [
      browserServiceProvider.overrideWithValue(browserService),
      ruleServiceProvider.overrideWithValue(ruleService),
      registrationServiceProvider.overrideWithValue(bindings.registrationService),
      startupServiceProvider.overrideWithValue(bindings.startupService),
      iconExtractorProvider.overrideWithValue(bindings.iconExtractor),
      iconsDirProvider.overrideWithValue(bindings.iconsDir),
      launchServiceProvider.overrideWithValue(bindings.launchService),
      localeFileProvider.overrideWithValue(bindings.localeFile),
      edgeWarningFileProvider.overrideWithValue(bindings.edgeWarningFile),
      appDataDirProvider.overrideWithValue(bindings.appDataDir),
    ],
  );

  container.read(updateInfoProvider);

  container.listen<AppState>(appStateProvider, (prev, next) async {
    if (prev?.mode == next.mode) return;
    switch (next.mode) {
      case AppMode.hidden:
        await windowManager.hide();
      case AppMode.settings:
        await windowManager.setSize(const Size(640, 700));
        await windowManager.center();
        await windowManager.setSkipTaskbar(false);
        await windowManager.setAlwaysOnTop(false);
      case AppMode.picker:
        final browsers = container.read(browsersProvider);
        final winSize = PickerLayout.windowSize(browsers.length);
        final (cursorX, cursorY) = await bindings.cursorLocator.cursorPosition();
        final (screenW, screenH) = await bindings.cursorLocator.screenSize();
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
    }
  });

  bindings.inboundEvents.listen((event) {
    switch (event) {
      case OpenUrlEvent(:final url):
        _log.info('Inbound: open_url $url');
        _handleUrl(url, container);
      case ShowSettingsEvent():
        _log.info('Inbound: show_settings');
        container.read(appStateProvider.notifier).showSettings();
    }
  });

  await _initTray(bindings, container);

  runApp(
    UncontrolledProviderScope(container: container, child: const NavigateApp()),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (bindings.initialEvent == null && !args.contains('--background')) {
      container.read(appStateProvider.notifier).showSettings();
    }
  });
}

Future<void> _firstBoot({
  required BrowserService browserService,
  required IconExtractor iconExtractor,
  required Directory iconsDir,
  required RegistrationService registrationService,
  required String executablePath,
}) async {
  await browserService.scanAndMerge();
  await iconsDir.create(recursive: true);
  for (final browser in browserService.browsers) {
    try {
      final outputPath = '${iconsDir.path}${Platform.pathSeparator}${browser.id}.png';
      await iconExtractor.extractIcon(browser.executablePath, outputPath);
    } on Exception catch (e) {
      _log.warning('Icon extraction failed for ${browser.name}: $e');
    }
  }
  await registrationService.register(executablePath);
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
  PlatformBindings bindings,
  ProviderContainer container,
) async {
  await bindings.trayController.init(
    title: 'LinkUnbound',
    iconPath: bindings.trayIconPath,
    tooltip: 'LinkUnbound — Browser Picker',
  );

  bindings.trayController.onActivated(
    () => container.read(appStateProvider.notifier).showSettings(),
  );

  await bindings.trayController.setMenu([
    TrayMenuItem(
      label: 'Settings',
      onClick: () => container.read(appStateProvider.notifier).showSettings(),
    ),
    const TrayMenuItem.separator(),
    TrayMenuItem(
      label: 'Exit',
      onClick: () async {
        await bindings.release();
        exit(0);
      },
    ),
  ]);
}
