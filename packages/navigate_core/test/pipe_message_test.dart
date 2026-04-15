import 'dart:convert';

import 'package:navigate_core/navigate_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenUrlMessage', () {
    test('encode produces correct JSON', () {
      const msg = OpenUrlMessage('https://example.com');
      final json = jsonDecode(msg.encode()) as Map<String, dynamic>;
      expect(json['action'], 'open_url');
      expect(json['url'], 'https://example.com');
    });

    test('decode round-trips', () {
      const original = OpenUrlMessage('https://test.com');
      final decoded = PipeMessage.decode(original.encode());
      expect(decoded, isA<OpenUrlMessage>());
      expect((decoded as OpenUrlMessage).url, 'https://test.com');
    });
  });

  group('ShowSettingsMessage', () {
    test('encode produces correct JSON', () {
      const msg = ShowSettingsMessage();
      final json = jsonDecode(msg.encode()) as Map<String, dynamic>;
      expect(json['action'], 'show_settings');
    });

    test('decode round-trips', () {
      const original = ShowSettingsMessage();
      final decoded = PipeMessage.decode(original.encode());
      expect(decoded, isA<ShowSettingsMessage>());
    });
  });

  group('PingMessage', () {
    test('encode produces correct JSON', () {
      const msg = PingMessage();
      final json = jsonDecode(msg.encode()) as Map<String, dynamic>;
      expect(json['action'], 'ping');
    });

    test('decode round-trips', () {
      const original = PingMessage();
      final decoded = PipeMessage.decode(original.encode());
      expect(decoded, isA<PingMessage>());
    });
  });

  group('decode errors', () {
    test('unknown action throws FormatException', () {
      expect(
        () => PipeMessage.decode('{"action": "unknown"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing action throws FormatException', () {
      expect(
        () => PipeMessage.decode('{"url": "https://x.com"}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
