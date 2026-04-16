import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

StateError _mustOverride() => StateError('Override at startup');

final browserServiceProvider = Provider<BrowserService>(
  (_) => throw _mustOverride(),
);

final ruleServiceProvider = Provider<RuleService>((_) => throw _mustOverride());

final registrationServiceProvider = Provider<RegistrationService>(
  (_) => throw _mustOverride(),
);

final startupServiceProvider = Provider<StartupService>(
  (_) => throw _mustOverride(),
);

final iconExtractorProvider = Provider<IconExtractor>(
  (_) => throw _mustOverride(),
);

final iconsDirProvider = Provider<Directory>((_) => throw _mustOverride());

final launchServiceProvider = Provider<LaunchService>(
  (_) => throw _mustOverride(),
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

final browsersProvider = NotifierProvider<BrowsersNotifier, List<Browser>>(
  BrowsersNotifier.new,
);

final class BrowsersNotifier extends Notifier<List<Browser>> {
  @override
  List<Browser> build() => ref.read(browserServiceProvider).browsers;

  Future<void> refresh() async {
    final service = ref.read(browserServiceProvider);
    await service.scanAndMerge();
    state = service.browsers;
  }

  Future<void> add(Browser browser) async {
    final service = ref.read(browserServiceProvider);
    service.addBrowser(browser);
    await service.save();
    state = service.browsers;
  }

  Future<void> remove(String id) async {
    final service = ref.read(browserServiceProvider);
    service.removeBrowser(id);
    await service.save();
    state = service.browsers;
  }

  Future<void> update(String id, Browser browser) async {
    final service = ref.read(browserServiceProvider);
    service.updateBrowser(id, browser);
    await service.save();
    state = service.browsers;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final service = ref.read(browserServiceProvider);
    service.reorder(oldIndex, newIndex);
    await service.save();
    state = service.browsers;
  }
}

final rulesProvider = NotifierProvider<RulesNotifier, List<Rule>>(
  RulesNotifier.new,
);

final class RulesNotifier extends Notifier<List<Rule>> {
  @override
  List<Rule> build() => ref.read(ruleServiceProvider).rules;

  Future<void> updateRule(String domain, {required String browserId}) async {
    final service = ref.read(ruleServiceProvider);
    service.updateRule(domain, browserId: browserId);
    await service.save();
    state = service.rules;
  }

  Future<void> removeRule(String domain) async {
    final service = ref.read(ruleServiceProvider);
    service.removeRule(domain);
    await service.save();
    state = service.rules;
  }
}

final isDefaultBrowserProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.read(registrationServiceProvider).isDefault;
});

final isStartupEnabledProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.read(startupServiceProvider).isEnabled;
});
