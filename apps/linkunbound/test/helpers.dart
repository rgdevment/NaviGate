import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:linkunbound/l10n/app_localizations.dart';
import 'package:linkunbound/providers.dart';

final class FakeRegistrationService implements RegistrationService {
  FakeRegistrationService({this.isDefaultValue = false});
  final bool isDefaultValue;

  @override
  Future<void> register(String executablePath) async {}

  @override
  Future<void> unregister() async {}

  @override
  Future<bool> get isDefault async => isDefaultValue;
}

final class FakeStartupService implements StartupService {
  FakeStartupService({this.isEnabledValue = false});
  final bool isEnabledValue;

  @override
  Future<void> enable(String executablePath) async {}

  @override
  Future<void> disable() async {}

  @override
  Future<bool> get isEnabled async => isEnabledValue;
}

final class FakeLaunchService implements LaunchService {
  final List<String> launches = [];

  @override
  Future<void> launch(
    String executablePath,
    String url,
    List<String> extraArgs,
  ) async {
    launches.add(executablePath);
  }
}

final class FakeIconExtractor implements IconExtractor {
  @override
  Future<String> extractIcon(
    String executablePath,
    String outputPath,
  ) async => outputPath;
}

final class FakeBrowserDetector implements BrowserDetector {
  FakeBrowserDetector([this.browsers = const []]);
  final List<Browser> browsers;

  @override
  Future<List<Browser>> detect() async => browsers;
}

Widget buildTestApp(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

({
  List<Override> overrides,
  BrowserService browserService,
  RuleService ruleService,
  FakeLaunchService launchService,
  Directory tempDir,
}) makeFixtures({
  Directory? dir,
  List<Browser> browsers = const [],
  List<Rule> rules = const [],
  bool isDefault = false,
  bool isStartupEnabled = false,
}) {
  final tempDir = dir ?? Directory.systemTemp.createTempSync('lu_test_');
  final configFile = File('${tempDir.path}/browsers.json');
  final rulesFile = File('${tempDir.path}/rules.json');
  final localeFile = File('${tempDir.path}/locale');
  final iconsDir = Directory('${tempDir.path}/icons')..createSync();

  final browserService = BrowserService(
    configFile: configFile,
    browserDetector: FakeBrowserDetector([]),
  );
  for (final b in browsers) {
    browserService.addBrowser(b);
  }

  final ruleService = RuleService(rulesFile: rulesFile);
  for (final r in rules) {
    ruleService.addRule(r);
  }

  final launchService = FakeLaunchService();

  final overrides = <Override>[
    browserServiceProvider.overrideWithValue(browserService),
    ruleServiceProvider.overrideWithValue(ruleService),
    registrationServiceProvider.overrideWithValue(
      FakeRegistrationService(isDefaultValue: isDefault),
    ),
    startupServiceProvider.overrideWithValue(
      FakeStartupService(isEnabledValue: isStartupEnabled),
    ),
    launchServiceProvider.overrideWithValue(launchService),
    iconExtractorProvider.overrideWithValue(FakeIconExtractor()),
    iconsDirProvider.overrideWithValue(iconsDir),
    localeFileProvider.overrideWithValue(localeFile),
    packageInfoProvider.overrideWith(
      (ref) async => PackageInfo(
        appName: 'LinkUnbound',
        packageName: 'linkunbound',
        version: '1.0.0',
        buildNumber: '1',
      ),
    ),
    updateInfoProvider.overrideWith((ref) async => null),
  ];

  return (
    overrides: overrides,
    browserService: browserService,
    ruleService: ruleService,
    launchService: launchService,
    tempDir: tempDir,
  );
}
