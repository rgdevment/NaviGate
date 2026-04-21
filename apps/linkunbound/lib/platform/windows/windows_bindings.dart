import 'dart:async';
import 'dart:io';

import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:logging/logging.dart';

import '../cursor_locator.dart';
import '../platform_bindings.dart';
import '../tray_controller.dart';
import 'win_browser_detector.dart';
import 'win_icon_extractor.dart';
import 'win_instance.dart';
import 'win_launch_service.dart';
import 'win_pipe_server.dart';
import 'win_registration_service.dart';
import 'win_startup_service.dart';
import 'windows_tray_controller.dart';

final _log = Logger('WindowsBindings');
final _windowsAbsPath = RegExp(r'^[a-zA-Z]:[\\/]');

final class WindowsBindings implements PlatformBindings {
  WindowsBindings._({
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
    required this.initialEvent,
    required this.startsHidden,
    required WinInstance instance,
    required WinPipeServer pipeServer,
  }) : _instance = instance,
       _pipeServer = pipeServer;

  static Future<WindowsBindings> create(List<String> args) async {
    final baseDir =
        Platform.environment['APPDATA'] ??
        Platform.environment['LOCALAPPDATA'] ??
        '${Platform.environment['USERPROFILE'] ?? Directory.systemTemp.path}\\AppData\\Roaming';
    final appDataDir = Directory('$baseDir\\LinkUnbound');
    try {
      await appDataDir.create(recursive: true);
    } on FileSystemException catch (e) {
      _log.severe('Could not create app data dir at ${appDataDir.path}', e);
    }

    return WindowsBindings._(
      browserDetector: WinBrowserDetector(),
      iconExtractor: WinIconExtractor(),
      registrationService: WinRegistrationService(),
      startupService: WinStartupService(),
      launchService: WinLaunchService(),
      trayController: WindowsTrayController(),
      cursorLocator: const ScreenRetrieverCursorLocator(),
      appDataDir: appDataDir,
      iconsDir: Directory('${appDataDir.path}\\icons'),
      browsersFile: File('${appDataDir.path}\\browsers.json'),
      rulesFile: File('${appDataDir.path}\\rules.json'),
      logFile: File('${appDataDir.path}\\navigate.log'),
      localeFile: File('${appDataDir.path}\\locale'),
      edgeWarningFile: File('${appDataDir.path}\\edge_warning_dismissed'),
      initialEvent: _parseInitialEvent(args),
      startsHidden: args.contains('--background'),
      instance: WinInstance(),
      pipeServer: WinPipeServer(),
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
  @override
  final InboundEvent? initialEvent;
  @override
  final bool startsHidden;

  final WinInstance _instance;
  final WinPipeServer _pipeServer;

  @override
  String get executablePath => Platform.resolvedExecutable;

  @override
  String get trayIconPath => 'assets/app_icon.ico';

  @override
  Stream<InboundEvent> get inboundEvents {
    final initial = initialEvent;
    if (initial == null) return _pipeServer.events;
    return _prependInitial(initial, _pipeServer.events);
  }

  static Stream<InboundEvent> _prependInitial(
    InboundEvent first,
    Stream<InboundEvent> rest,
  ) async* {
    yield first;
    yield* rest;
  }

  @override
  Future<bool> tryDelegate(InboundEvent? event) async {
    final client = WinPipeClient();
    final payload = event ?? const ShowSettingsEvent();
    WinInstance.allowForeground();
    return client.send(payload);
  }

  @override
  Future<bool> claim() async {
    if (!_instance.acquire()) {
      _log.warning('Mutex held but pipe unreachable');
      return false;
    }
    try {
      await _pipeServer.start();
    } on Exception catch (e) {
      _log.warning('Pipe server failed to start: $e');
    }
    return true;
  }

  @override
  Future<void> release() async {
    await _pipeServer.stop();
    _instance.release();
  }

  static InboundEvent? _parseInitialEvent(List<String> args) {
    for (final arg in args) {
      final resolved = stripEdgeProtocol(arg);
      final uri = Uri.tryParse(resolved);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return OpenUrlEvent(resolved);
      }
      if (uri != null && uri.scheme == 'file') return OpenUrlEvent(arg);
      if (_windowsAbsPath.hasMatch(arg)) return OpenUrlEvent(arg);
    }
    return null;
  }
}
