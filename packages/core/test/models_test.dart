import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:test/test.dart';

void main() {
  group('Browser', () {
    const base = Browser(
      id: 'chrome',
      name: 'Chrome',
      executablePath: 'C:\\chrome.exe',
      iconPath: 'icons/chrome.png',
      extraArgs: ['--flag'],
      isCustom: false,
    );

    group('copyWith', () {
      test('no overrides returns equivalent browser', () {
        final copy = base.copyWith();
        expect(copy.id, base.id);
        expect(copy.name, base.name);
        expect(copy.executablePath, base.executablePath);
        expect(copy.iconPath, base.iconPath);
        expect(copy.extraArgs, base.extraArgs);
        expect(copy.isCustom, base.isCustom);
      });

      test('overrides name only', () {
        final copy = base.copyWith(name: 'Chromium');
        expect(copy.name, 'Chromium');
        expect(copy.id, base.id);
        expect(copy.executablePath, base.executablePath);
      });

      test('overrides multiple fields', () {
        final copy = base.copyWith(
          extraArgs: ['--incognito'],
          isCustom: true,
          iconPath: 'icons/custom.png',
        );
        expect(copy.extraArgs, ['--incognito']);
        expect(copy.isCustom, isTrue);
        expect(copy.iconPath, 'icons/custom.png');
        expect(copy.name, base.name);
      });

      test('overrides id and executablePath', () {
        final copy = base.copyWith(id: 'chromium', executablePath: 'D:\\chromium.exe');
        expect(copy.id, 'chromium');
        expect(copy.executablePath, 'D:\\chromium.exe');
        expect(copy.name, base.name);
      });
    });

    group('toJson / fromJson', () {
      test('round-trips all fields', () {
        final json = base.toJson();
        final restored = Browser.fromJson(json);
        expect(restored.id, base.id);
        expect(restored.name, base.name);
        expect(restored.executablePath, base.executablePath);
        expect(restored.iconPath, base.iconPath);
        expect(restored.extraArgs, base.extraArgs);
        expect(restored.isCustom, base.isCustom);
      });

      test('toJson includes all expected keys', () {
        final json = base.toJson();
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('name'), isTrue);
        expect(json.containsKey('executablePath'), isTrue);
        expect(json.containsKey('iconPath'), isTrue);
        expect(json.containsKey('extraArgs'), isTrue);
        expect(json.containsKey('isCustom'), isTrue);
      });

      test('default extraArgs is empty list', () {
        const b = Browser(
          id: 'x',
          name: 'X',
          executablePath: 'x.exe',
          iconPath: 'x.png',
        );
        expect(b.extraArgs, isEmpty);
        expect(b.isCustom, isFalse);
      });
    });
  });

  group('Rule', () {
    const base = Rule(domain: 'github.com', browserId: 'chrome');

    group('copyWith', () {
      test('no overrides returns equivalent rule', () {
        final copy = base.copyWith();
        expect(copy.domain, base.domain);
        expect(copy.browserId, base.browserId);
      });

      test('overrides browserId only', () {
        final copy = base.copyWith(browserId: 'firefox');
        expect(copy.browserId, 'firefox');
        expect(copy.domain, base.domain);
      });

      test('overrides domain only', () {
        final copy = base.copyWith(domain: 'gitlab.com');
        expect(copy.domain, 'gitlab.com');
        expect(copy.browserId, base.browserId);
      });

      test('overrides both fields', () {
        final copy = base.copyWith(domain: 'example.com', browserId: 'edge');
        expect(copy.domain, 'example.com');
        expect(copy.browserId, 'edge');
      });
    });

    group('toJson / fromJson', () {
      test('round-trips all fields', () {
        final json = base.toJson();
        final restored = Rule.fromJson(json);
        expect(restored.domain, base.domain);
        expect(restored.browserId, base.browserId);
      });

      test('toJson includes domain and browserId keys', () {
        final json = base.toJson();
        expect(json['domain'], 'github.com');
        expect(json['browserId'], 'chrome');
      });
    });
  });

  group('BrowserConfig', () {
    const chrome = Browser(
      id: 'chrome',
      name: 'Chrome',
      executablePath: 'chrome.exe',
      iconPath: 'chrome.png',
    );

    test('default constructor uses schema 1.0 and empty list', () {
      const config = BrowserConfig();
      expect(config.schemaVersion, '1.0');
      expect(config.browsers, isEmpty);
    });

    test('fromJson parses schema_version and browsers', () {
      final json = {
        'schema_version': '2.0',
        'browsers': [chrome.toJson()],
      };
      final config = BrowserConfig.fromJson(json);
      expect(config.schemaVersion, '2.0');
      expect(config.browsers, hasLength(1));
      expect(config.browsers.first.id, 'chrome');
    });

    test('fromJson defaults schema_version to 1.0 when absent', () {
      final config = BrowserConfig.fromJson({'browsers': []});
      expect(config.schemaVersion, '1.0');
    });

    test('fromJson defaults to empty browsers when field is absent', () {
      final config = BrowserConfig.fromJson(const {'schema_version': '1.0'});
      expect(config.browsers, isEmpty);
    });

    test('fromJson handles empty JSON object', () {
      final config = BrowserConfig.fromJson(const {});
      expect(config.schemaVersion, '1.0');
      expect(config.browsers, isEmpty);
    });

    test('toJson produces expected structure', () {
      const config = BrowserConfig(schemaVersion: '1.0', browsers: [chrome]);
      final json = config.toJson();
      expect(json['schema_version'], '1.0');
      expect((json['browsers'] as List), hasLength(1));
    });

    test('toJson / fromJson round-trips correctly', () {
      const original = BrowserConfig(browsers: [chrome]);
      final restored = BrowserConfig.fromJson(original.toJson());
      expect(restored.schemaVersion, original.schemaVersion);
      expect(restored.browsers.first.id, 'chrome');
    });
  });
}
