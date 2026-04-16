import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

final localeFileProvider = Provider<File>((_) => throw _mustOverride());

final edgeWarningFileProvider = Provider<File>((_) => throw _mustOverride());

final appDataDirProvider = Provider<Directory>((_) => throw _mustOverride());

final edgeWarningDismissedProvider =
    NotifierProvider<EdgeWarningNotifier, bool>(EdgeWarningNotifier.new);

final class EdgeWarningNotifier extends Notifier<bool> {
  @override
  bool build() {
    final file = ref.read(edgeWarningFileProvider);
    return file.existsSync();
  }

  void dismiss() {
    final file = ref.read(edgeWarningFileProvider);
    file.writeAsStringSync('1');
    state = true;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

final class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final file = ref.read(localeFileProvider);
    if (!file.existsSync()) return null;
    final code = file.readAsStringSync().trim();
    if (code == 'en' || code == 'es') return Locale(code);
    return null;
  }

  void setLocale(Locale? locale) {
    final file = ref.read(localeFileProvider);
    if (locale == null) {
      if (file.existsSync()) file.deleteSync();
    } else {
      file.writeAsStringSync(locale.languageCode);
    }
    state = locale;
  }
}

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

  Future<({int added, int removed})> refresh() async {
    final service = ref.read(browserServiceProvider);
    final result = await service.scanAndMerge();
    state = service.browsers;
    return result;
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

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

const _updateService = UpdateService(owner: 'rgdevment', repo: 'LinkUnbound');

final updateInfoProvider = FutureProvider<UpdateInfo?>((ref) async {
  final info = await ref.watch(packageInfoProvider.future);
  return _updateService.checkForUpdate(info.version);
});
