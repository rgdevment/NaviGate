import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:test/test.dart';

void main() {
  group('UpdateInfo', () {
    test('stores latestVersion and releaseUrl', () {
      const info = UpdateInfo(
        latestVersion: '2.1.0',
        releaseUrl: 'https://github.com/owner/repo/releases/tag/v2.1.0',
      );
      expect(info.latestVersion, '2.1.0');
      expect(info.releaseUrl, 'https://github.com/owner/repo/releases/tag/v2.1.0');
    });

    test('fields are accessible after construction', () {
      const info = UpdateInfo(latestVersion: '1.0.0', releaseUrl: 'https://example.com');
      expect(info.latestVersion, isNotEmpty);
      expect(info.releaseUrl, isNotEmpty);
    });
  });

  group('UpdateService', () {
    test('stores owner and repo', () {
      const service = UpdateService(owner: 'rgdevment', repo: 'LinkUnbound');
      expect(service.owner, 'rgdevment');
      expect(service.repo, 'LinkUnbound');
    });

    test('checkForUpdate returns null on network failure', () async {
      // Unresolvable host triggers the on-Exception path → null
      const service = UpdateService(owner: 'localhost-unreachable-host-xyz', repo: 'repo');
      final result = await service.checkForUpdate('1.0.0');
      expect(result, isNull);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
