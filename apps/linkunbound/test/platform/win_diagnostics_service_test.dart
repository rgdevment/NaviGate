import 'package:flutter_test/flutter_test.dart';

import 'package:linkunbound/platform/windows/win_diagnostics_service.dart';

void main() {
  group('parseWindowsVersion', () {
    test('returns Windows 11 for build 22000', () {
      const raw = 'Windows 10 Pro 10.0 (Build 22000)';
      expect(parseWindowsVersion(raw), contains('Windows 11'));
      expect(parseWindowsVersion(raw), isNot(contains('Windows 10')));
    });

    test('returns Windows 11 for build 26200', () {
      const raw = 'Windows 10 Pro 10.0 (Build 26200)';
      expect(parseWindowsVersion(raw), 'Windows 11 Pro 10.0 (Build 26200)');
    });

    test('keeps Windows 10 for build 21999', () {
      const raw = 'Windows 10 Pro 10.0 (Build 21999)';
      expect(parseWindowsVersion(raw), equals(raw));
    });

    test('returns raw string unchanged when no Build match', () {
      const raw = 'Windows 10 Pro 10.0';
      expect(parseWindowsVersion(raw), equals(raw));
    });

    test('does not modify string that already says Windows 11', () {
      const raw = 'Windows 11 Pro 10.0 (Build 22631)';
      expect(parseWindowsVersion(raw), equals(raw));
    });
  });
}
