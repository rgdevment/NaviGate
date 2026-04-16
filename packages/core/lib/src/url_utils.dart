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
