import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import '../models/browser.dart';
import '../models/browser_config.dart';
import '../platform/browser_detector.dart';

final class BrowserService {
  BrowserService({
    required this.configFile,
    required this.browserDetector,
  });

  final File configFile;
  final BrowserDetector browserDetector;
  final _log = Logger('BrowserService');

  List<Browser> _browsers = [];

  List<Browser> get browsers => List.unmodifiable(_browsers);

  Future<void> load() async {
    if (!configFile.existsSync()) {
      _browsers = [];
      return;
    }
    _log.info('Loading browsers from ${configFile.path}');
    final content = await configFile.readAsString();
    final config = BrowserConfig.fromJson(
      jsonDecode(content) as Map<String, dynamic>,
    );
    _browsers = config.browsers;
  }

  Future<void> save() async {
    _log.info('Saving ${_browsers.length} browsers to ${configFile.path}');
    await configFile.parent.create(recursive: true);
    final config = BrowserConfig(browsers: _browsers);
    const encoder = JsonEncoder.withIndent('  ');
    await configFile.writeAsString(encoder.convert(config.toJson()));
  }

  Future<void> scanAndMerge() async {
    _log.info('Scanning for browsers');
    final detected = await browserDetector.detect();
    final existingById = {for (final b in _browsers) b.id: b};
    final customBrowsers = _browsers.where((b) => b.isCustom).toList();

    final merged = [
      for (final d in detected)
        if (existingById[d.id] case final existing? when !existing.isCustom)
          d.copyWith(extraArgs: existing.extraArgs)
        else
          d,
      ...customBrowsers,
    ];

    _browsers = merged;
    _log.info(
      'Found ${detected.length} detected + ${customBrowsers.length} custom',
    );
  }

  void addBrowser(Browser browser) {
    _browsers = [..._browsers, browser];
  }

  void removeBrowser(String id) {
    _browsers = _browsers.where((b) => b.id != id).toList();
  }

  void updateBrowser(String id, Browser browser) {
    _browsers = [
      for (final b in _browsers)
        if (b.id == id) browser else b,
    ];
  }

  Future<void> reset() async {
    _browsers = [];
    if (configFile.existsSync()) {
      await configFile.delete();
    }
    _log.info('Browser config reset');
  }
}
