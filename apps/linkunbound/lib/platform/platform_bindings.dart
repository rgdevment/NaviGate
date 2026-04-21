import 'dart:io';

import 'package:linkunbound_core/linkunbound_core.dart';

import 'cursor_locator.dart';
import 'tray_controller.dart';

abstract class PlatformBindings {
  BrowserDetector get browserDetector;
  IconExtractor get iconExtractor;
  RegistrationService get registrationService;
  StartupService get startupService;
  LaunchService get launchService;
  TrayController get trayController;
  CursorLocator get cursorLocator;

  Stream<InboundEvent> get inboundEvents;

  Future<bool> tryDelegate(InboundEvent event);

  Future<void> claim();

  Future<void> release();

  Directory get appDataDir;
  Directory get iconsDir;
  File get browsersFile;
  File get rulesFile;
  File get logFile;
  File get localeFile;
  File get edgeWarningFile;
}
