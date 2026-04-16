import 'dart:convert';
import 'dart:io';

final class UpdateInfo {
  const UpdateInfo({required this.latestVersion, required this.releaseUrl});

  final String latestVersion;
  final String releaseUrl;
}

final class UpdateService {
  const UpdateService({required this.owner, required this.repo});

  final String owner;
  final String repo;

  Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest'),
      );
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      request.headers.set('User-Agent', 'LinkUnbound/$currentVersion');

      final response = await request.close();
      if (response.statusCode != 200) {
        client.close();
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String?;
      final htmlUrl = json['html_url'] as String?;
      if (tagName == null || htmlUrl == null) return null;

      final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

      if (!_isNewer(version, currentVersion)) return null;

      return UpdateInfo(latestVersion: version, releaseUrl: htmlUrl);
    } on Exception {
      return null;
    }
  }

  static bool _isNewer(String latest, String current) {
    final partsL = latest.split('.').map(int.tryParse).toList();
    final partsC = current.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final l = i < partsL.length ? (partsL[i] ?? 0) : 0;
      final c = i < partsC.length ? (partsC[i] ?? 0) : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
