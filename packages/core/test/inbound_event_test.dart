import 'dart:convert';

import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenUrlEvent', () {
    test('encode produces correct JSON', () {
      const event = OpenUrlEvent('https://example.com');
      final json = jsonDecode(event.encode()) as Map<String, dynamic>;
      expect(json['action'], 'open_url');
      expect(json['url'], 'https://example.com');
    });

    test('decode round-trips', () {
      const original = OpenUrlEvent('https://test.com');
      final decoded = InboundEvent.decode(original.encode());
      expect(decoded, isA<OpenUrlEvent>());
      expect((decoded as OpenUrlEvent).url, 'https://test.com');
    });
  });

  group('ShowSettingsEvent', () {
    test('encode produces correct JSON', () {
      const event = ShowSettingsEvent();
      final json = jsonDecode(event.encode()) as Map<String, dynamic>;
      expect(json['action'], 'show_settings');
    });

    test('decode round-trips', () {
      const original = ShowSettingsEvent();
      final decoded = InboundEvent.decode(original.encode());
      expect(decoded, isA<ShowSettingsEvent>());
    });
  });

  group('decode errors', () {
    test('unknown action throws FormatException', () {
      expect(
        () => InboundEvent.decode('{"action": "unknown"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing action throws FormatException', () {
      expect(
        () => InboundEvent.decode('{"url": "https://x.com"}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
