String stripEdgeProtocol(String raw) {
  const prefixes = [
    'microsoft-edge-https://',
    'microsoft-edge://',
    'microsoft-edge:',
  ];
  final lower = raw.toLowerCase();
  for (final prefix in prefixes) {
    if (lower.startsWith(prefix)) {
      final inner = raw.substring(prefix.length);
      if (prefix.contains('-https')) return 'https://$inner';
      return inner;
    }
  }
  return raw;
}

String unwrapSafeLink(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null) return raw;

  final host = uri.host.toLowerCase();
  final isSafeLink =
      host.endsWith('.safelinks.protection.outlook.com') ||
      host == 'statics.teams.cdn.office.net';
  if (!isSafeLink) return raw;

  final inner = uri.queryParameters['url'];
  if (inner == null || inner.isEmpty) return raw;

  final decoded = Uri.decodeFull(inner);
  final innerUri = Uri.tryParse(decoded);
  if (innerUri == null) return raw;
  if (innerUri.scheme != 'http' && innerUri.scheme != 'https') return raw;

  return decoded;
}
