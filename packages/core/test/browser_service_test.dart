import 'dart:convert';
import 'dart:io';

import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:test/test.dart';

final class _FakeDetector implements BrowserDetector {
  _FakeDetector(this._browsers);
  final List<Browser> _browsers;

  @override
  Future<List<Browser>> detect() async => _browsers;
}

void main() {
  late Directory tempDir;
  late File configFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('browser_service_test_');
    configFile = File('${tempDir.path}/browsers.json');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('load/save', () {
    test('save creates file and load restores browsers', () async {
      final service = BrowserService(
        configFile: configFile,
        browserDetector: _FakeDetector([]),
      );
      service.addBrowser(
        const Browser(
          id: 'chrome',
          name: 'Chrome',
          executablePath: 'C:\\chrome.exe',
          iconPath: 'icons/chrome.png',
        ),
      );
      await service.save();
      expect(configFile.existsSync(), isTrue);

      final fresh = BrowserService(
        configFile: configFile,
        browserDetector: _FakeDetector([]),
      );
      await fresh.load();
      expect(fresh.browsers, hasLength(1));
      expect(fresh.browsers.first.id, 'chrome');
    });

    test('load with missing file yields empty list', () async {
      final service = BrowserService(
        configFile: configFile,
        browserDetector: _FakeDetector([]),
      );
      await service.load();
      expect(service.browsers, isEmpty);
    });

    test('save writes schema_version', () async {
      final service = BrowserService(
        configFile: configFile,
        browserDetector: _FakeDetector([]),
      );
      await service.save();
      final json =
          jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
      expect(json['schema_version'], '1.0');
    });
  });

  group('scanAndMerge', () {
    test('detected browsers are added', () async {
      final detected = [
        const Browser(
          id: 'chrome',
          name: 'Chrome',
          executablePath: 'C:\\chrome.exe',
          iconPath: 'icons/chrome.png',
        ),
        const Browser(
          id: 'firefox',
          name: 'Firefox',
          executablePath: 'C:\\firefox.exe',
          iconPath: 'icons/firefox.png',
        ),
      ];
      final service = BrowserService(
        configFile: configFile,
        browserDetector: _FakeDetector(detected),
      );
      await service.scanAndMerge();
      expect(service.browsers, hasLength(2));
    });

    test('custom browsers survive scan', () async {
      final service = BrowserService(
        configFile: configFile,
        browserDetector: _FakeDetector([
          const Browser(
            id: 'chrome',
            name: 'Chrome',
            executablePath: 'C:\\chrome.exe',
            iconPath: 'icons/chrome.png',
          ),
        ]),
      );
      service.addBrowser(
        const Browser(
          id: 'my-browser',
          name: 'My Browser',
          executablePath: 'D:\\my.exe',
          iconPath: 'icons/my.png',
          isCustom: true,
        ),
      );
      await service.scanAndMerge();
      expect(service.browsers, hasLength(2));
      expect(service.browsers.any((b) => b.id == 'my-browser'), isTrue);
    });

    test('user extraArgs preserved on detected browser after rescan', () async {
      final service = BrowserService(
        configFile: configFile,
        browserDetector: _FakeDetector([
          const Browser(
            id: 'chrome',
            name: 'Chrome',
            executablePath: 'C:\\chrome.exe',
            iconPath: 'icons/chrome.png',
          ),
        ]),
      );
      service.addBrowser(
        const Browser(
          id: 'chrome',
          name: 'Chrome',
          executablePath: 'C:\\chrome.exe',
          iconPath: 'icons/chrome.png',
          extraArgs: ['--incognito'],
        ),
      );
      await service.scanAndMerge();
      final chrome = service.browsers.firstWhere((b) => b.id == 'chrome');
      expect(chrome.extraArgs, contains('--incognito'));
    });
  });

  group('CRUD', () {
    test('addBrowser and removeBrowser', () {
      final service = BrowserService(
        configFile: configFile,
        browserDetector: _FakeDetector([]),
      );
      service.addBrowser(
        const Browser(
          id: 'x',
          name: 'X',
          executablePath: 'x.exe',
          iconPath: 'x.png',
        ),
      );
      expect(service.browsers, hasLength(1));
      service.removeBrowser('x');
      expect(service.browsers, isEmpty);
    });

    test('updateBrowser replaces by id', () {
      final service = BrowserService(
        configFile: configFile,
        browserDetector: _FakeDetector([]),
      );
      service.addBrowser(
        const Browser(
          id: 'x',
          name: 'X',
          executablePath: 'x.exe',
          iconPath: 'x.png',
        ),
      );
      service.updateBrowser(
        'x',
        const Browser(
          id: 'x',
          name: 'Updated',
          executablePath: 'x.exe',
          iconPath: 'x.png',
        ),
      );
      expect(service.browsers.first.name, 'Updated');
    });
  });

  group('reset', () {
    test('reset clears browsers and deletes file', () async {
      final service = BrowserService(
        configFile: configFile,
        browserDetector: _FakeDetector([]),
      );
      service.addBrowser(
        const Browser(
          id: 'x',
          name: 'X',
          executablePath: 'x.exe',
          iconPath: 'x.png',
        ),
      );
      await service.save();
      expect(configFile.existsSync(), isTrue);

      await service.reset();
      expect(service.browsers, isEmpty);
      expect(configFile.existsSync(), isFalse);
    });
  });

  group('reorder', () {
    BrowserService serviceWithBrowsers(List<String> ids) {
      final service = BrowserService(
        configFile: configFile,
        browserDetector: _FakeDetector([]),
      );
      for (final id in ids) {
        service.addBrowser(
          Browser(id: id, name: id, executablePath: '$id.exe', iconPath: '$id.png'),
        );
      }
      return service;
    }

    test('moves item forward in list', () {
      final service = serviceWithBrowsers(['a', 'b', 'c']);
      service.reorder(0, 2);
      expect(service.browsers.map((b) => b.id).toList(), ['b', 'c', 'a']);
    });

    test('moves item backward in list', () {
      final service = serviceWithBrowsers(['a', 'b', 'c']);
      service.reorder(2, 0);
      expect(service.browsers.map((b) => b.id).toList(), ['c', 'a', 'b']);
    });

    test('moves item one position forward', () {
      final service = serviceWithBrowsers(['a', 'b', 'c']);
      service.reorder(0, 1);
      expect(service.browsers.map((b) => b.id).toList(), ['b', 'a', 'c']);
    });

    test('clamps newIndex to list length when out of bounds', () {
      final service = serviceWithBrowsers(['a', 'b', 'c']);
      service.reorder(0, 99);
      expect(service.browsers.map((b) => b.id).toList(), ['b', 'c', 'a']);
    });

    test('clamps newIndex to 0 when negative', () {
      final service = serviceWithBrowsers(['a', 'b', 'c']);
      service.reorder(2, -1);
      expect(service.browsers.map((b) => b.id).toList(), ['c', 'a', 'b']);
    });
  });
}
