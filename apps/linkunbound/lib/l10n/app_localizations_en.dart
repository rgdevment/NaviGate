// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get copyUrl => 'Copy URL';

  @override
  String get alwaysOpenHere => 'Always open here';

  @override
  String get tabGeneral => 'General';

  @override
  String get tabRules => 'Rules';

  @override
  String get tabAbout => 'About';

  @override
  String get sectionDefaultBrowser => 'DEFAULT BROWSER';

  @override
  String get isDefaultBrowser => 'LinkUnbound is set as the default browser';

  @override
  String get notDefaultBrowser => 'LinkUnbound is not the default browser';

  @override
  String get setDefault => 'Set default';

  @override
  String get sectionStartup => 'STARTUP';

  @override
  String get launchAtStartup => 'Launch at Windows startup';

  @override
  String get sectionLanguage => 'LANGUAGE';

  @override
  String get languageAuto => 'Automatic (system)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get sectionBrowsers => 'BROWSERS';

  @override
  String get addBrowserTooltip => 'Add custom browser';

  @override
  String get refreshBrowsersTooltip => 'Refresh browsers';

  @override
  String get menuEdit => 'Edit';

  @override
  String get menuDuplicate => 'Duplicate';

  @override
  String get menuRemove => 'Remove';

  @override
  String foundBrowsersCount(int count) {
    return 'Found $count browsers';
  }

  @override
  String get editBrowserTitle => 'Edit browser';

  @override
  String get addBrowserTitle => 'Add custom browser';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldExecutablePath => 'Executable path';

  @override
  String get fieldExtraArgs => 'Extra arguments (space-separated)';

  @override
  String get fieldIconPath => 'Custom icon path (optional)';

  @override
  String get fieldIconHint => 'Leave empty to auto-detect from exe';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get sectionUrlRules => 'URL RULES';

  @override
  String get noRulesYet =>
      'No rules yet. Rules are created from the browser picker when you check \"Always open here\".';

  @override
  String get columnDomain => 'Domain';

  @override
  String get columnBrowser => 'Browser';

  @override
  String get deleteRuleTitle => 'Delete rule';

  @override
  String deleteRuleContent(String domain) {
    return 'Remove the rule for \"$domain\"?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get deleteRuleTooltip => 'Delete rule';

  @override
  String get sectionAbout => 'ABOUT';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get appDescription => 'Open-source browser picker for Windows.';

  @override
  String get mitLicense => 'MIT License';

  @override
  String get sectionActions => 'ACTIONS';

  @override
  String get resetConfigLabel => 'Reset configuration';

  @override
  String get resetConfigDescription =>
      'Clear all browsers and rules, then re-scan';

  @override
  String get unregisterLabel => 'Unregister LinkUnbound';

  @override
  String get unregisterDescription => 'Remove from Windows browser list';

  @override
  String get resetConfigTitle => 'Reset configuration';

  @override
  String get resetConfigContent =>
      'This will delete all browsers, rules and icons, then re-scan installed browsers. Continue?';

  @override
  String get reset => 'Reset';

  @override
  String get unregisterTitle => 'Unregister LinkUnbound';

  @override
  String get unregisterContent =>
      'This will remove LinkUnbound from the Windows browser list. You may need to change your default browser in Windows Settings afterwards. Continue?';

  @override
  String get unregisterAction => 'Unregister';
}
