import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navigate_core/navigate_core.dart';

final browserServiceProvider = Provider<BrowserService>(
  (_) => throw StateError('Override at startup'),
);

final ruleServiceProvider = Provider<RuleService>(
  (_) => throw StateError('Override at startup'),
);

final registrationServiceProvider = Provider<RegistrationService>(
  (_) => throw StateError('Override at startup'),
);

final startupServiceProvider = Provider<StartupService>(
  (_) => throw StateError('Override at startup'),
);

final iconExtractorProvider = Provider<IconExtractor>(
  (_) => throw StateError('Override at startup'),
);

final iconsDirProvider = Provider<Directory>(
  (_) => throw StateError('Override at startup'),
);

enum AppMode { hidden, settings, picker }

final class AppState {
  const AppState({this.mode = AppMode.hidden, this.pendingUrl});
  final AppMode mode;
  final String? pendingUrl;
}

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);

final class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() => const AppState();

  void showSettings() => state = const AppState(mode: AppMode.settings);

  void showPicker(String url) =>
      state = AppState(mode: AppMode.picker, pendingUrl: url);

  void hide() => state = const AppState();
}

