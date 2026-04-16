import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:test/test.dart';

void main() {
  group('stripEdgeProtocol', () {
    test('returns plain https URL unchanged', () {
      expect(stripEdgeProtocol('https://example.com'), 'https://example.com');
    });

    test('returns plain http URL unchanged', () {
      expect(stripEdgeProtocol('http://example.com'), 'http://example.com');
    });

    test('strips microsoft-edge: wrapping an https URL', () {
      expect(
        stripEdgeProtocol('microsoft-edge:https://example.com/path?q=1'),
        'https://example.com/path?q=1',
      );
    });

    test('strips microsoft-edge: wrapping an http URL', () {
      expect(
        stripEdgeProtocol('microsoft-edge:http://example.com'),
        'http://example.com',
      );
    });

    test('strips microsoft-edge-https:// prefix', () {
      expect(
        stripEdgeProtocol('microsoft-edge-https://example.com/page'),
        'https://example.com/page',
      );
    });

    test('is case-insensitive for the prefix', () {
      expect(
        stripEdgeProtocol('Microsoft-Edge:https://example.com'),
        'https://example.com',
      );
      expect(
        stripEdgeProtocol('MICROSOFT-EDGE-HTTPS://example.com'),
        'https://example.com',
      );
    });

    test('returns non-URL strings unchanged', () {
      expect(stripEdgeProtocol('--flag'), '--flag');
    });

    test('returns empty string unchanged', () {
      expect(stripEdgeProtocol(''), '');
    });

    test('preserves URL with query and fragment', () {
      const input = 'microsoft-edge:https://example.com/p?a=1&b=2#section';
      expect(stripEdgeProtocol(input), 'https://example.com/p?a=1&b=2#section');
    });
  });
}
