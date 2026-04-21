import 'dart:io';

/// File extensions LinkUnbound is willing to forward to a browser when the
/// inbound URL has the `file://` scheme. Mirrors `LSItemContentTypes` declared
/// in the macOS `Info.plist` (`public.html`, `public.xhtml`).
const Set<String> kLocalFileWebExtensions = {'.html', '.htm', '.xhtml'};

/// Validates a `file://` URL coming from the OS:
/// - must parse as a `Uri`,
/// - must resolve to an existing regular file,
/// - extension must be in [kLocalFileWebExtensions].
///
/// Returns the resolved absolute path on success, or `null` otherwise. Callers
/// should treat `null` as "drop the event silently" — never echo the raw input
/// back to the user (see [redactPath]).
String? resolveLocalWebFile(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || uri.scheme != 'file') return null;

  final String path;
  try {
    path = uri.toFilePath();
  } on UnsupportedError {
    return null;
  }

  final ext = _extension(path);
  if (!kLocalFileWebExtensions.contains(ext)) return null;

  final file = File(path);
  if (!file.existsSync()) return null;

  // Resolve symlinks so the browser doesn't follow a link into a place the
  // user wouldn't expect — and so logs stay consistent.
  try {
    return file.resolveSymbolicLinksSync();
  } on FileSystemException {
    return null;
  }
}

String _extension(String path) {
  final slash = path.lastIndexOf(Platform.pathSeparator);
  final name = slash >= 0 ? path.substring(slash + 1) : path;
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return '';
  return name.substring(dot).toLowerCase();
}

/// Redacts a filesystem path for logging — keeps only the basename and a
/// shortened parent (`…/parent/file.html`). Avoids leaking `$HOME` and
/// project-internal paths into shared diagnostic bundles.
String redactPath(String path) {
  final sep = Platform.pathSeparator;
  final parts = path.split(sep).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '<empty>';
  if (parts.length == 1) return '…/${parts.last}';
  return '…/${parts[parts.length - 2]}/${parts.last}';
}
