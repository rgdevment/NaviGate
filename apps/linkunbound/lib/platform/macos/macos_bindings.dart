import 'dart:async';
import 'dart:io';

import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

import '../cursor_locator.dart';
import '../platform_bindings.dart';
import '../tray_controller.dart';
import 'mac_browser_detector.dart';
import 'mac_icon_extractor.dart';
import 'mac_inbound_events.dart';
import 'mac_launch_service.dart';
import 'mac_registration_service.dart';
import 'mac_startup_service.dart';
import 'macos_tray_controller.dart';

final _log = Logger('MacOsBindings');

final class MacOsBindings implements PlatformBindings {
  MacOsBindings._({
    required this.browserDetector,
    required this.iconExtractor,
    required this.registrationService,
    required this.startupService,
    required this.launchService,
    required this.trayController,
    required this.cursorLocator,
    required this.appDataDir,
    required this.iconsDir,
    required this.browsersFile,
    required this.rulesFile,
    required this.logFile,
    required this.localeFile,
    required this.edgeWarningFile,
    required MacInboundEvents inboundServer,
  }) : _inboundServer = inboundServer;

  static Future<MacOsBindings> create() async {
    final supportDir = await getApplicationSupportDirectory();
    final appDataDir = Directory('${supportDir.path}/LinkUnbound');
    await appDataDir.create(recursive: true);

    return MacOsBindings._(
      browserDetector: MacBrowserDetector(),
      iconExtractor: MacIconExtractor(),
      registrationService: MacRegistrationService(),
      startupService: MacStartupService(),
      launchService: MacLaunchService(),
      trayController: MacOsTrayController(),
      cursorLocator: const ScreenRetrieverCursorLocator(),
      appDataDir: appDataDir,
      iconsDir: Directory('${appDataDir.path}/icons'),
      browsersFile: File('${appDataDir.path}/browsers.json'),
      rulesFile: File('${appDataDir.path}/rules.json'),
      logFile: File('${appDataDir.path}/navigate.log'),
      localeFile: File('${appDataDir.path}/locale'),
      edgeWarningFile: File('${appDataDir.path}/edge_warning_dismissed'),
      inboundServer: MacInboundEvents(),
    );
  }

  @override
  final BrowserDetector browserDetector;
  @override
  final IconExtractor iconExtractor;
  @override
  final RegistrationService registrationService;
  @override
  final StartupService startupService;
  @override
  final LaunchService launchService;
  @override
  final TrayController trayController;
  @override
  final CursorLocator cursorLocator;
  @override
  final Directory appDataDir;
  @override
  final Directory iconsDir;
  @override
  final File browsersFile;
  @override
  final File rulesFile;
  @override
  final File logFile;
  @override
  final File localeFile;
  @override
  final File edgeWarningFile;

  final MacInboundEvents _inboundServer;

  /// macOS receives URLs via Apple Events, never via argv.
  @override
  InboundEvent? get initialEvent => null;

  @override
  Stream<InboundEvent> get inboundEvents => _inboundServer.events;

  @override
  String get executablePath => Platform.resolvedExecutable;

  @override
  String get trayIconPath => 'assets/LinkUnbound_tray_64.png';

  /// Single-instance enforcement is handled by `NSApplication` (LSMultipleInstancesProhibited
  /// is implicit for `.app` bundles double-launched from Finder). A second
  /// process from the CLI would be rare; we don't attempt IPC for it.
  @override
  Future<bool> tryDelegate(InboundEvent? event) async => false;

  @override
  Future<bool> claim() async {
    await _inboundServer.start();
    _log.info('macOS bindings ready');
    return true;
  }

  @override
  Future<void> release() async {
    await trayController.dispose();
    await _inboundServer.stop();
  }
}
