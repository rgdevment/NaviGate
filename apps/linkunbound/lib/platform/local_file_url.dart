import 'dart:io';

/// File extensions LinkUnbound accepts as inbound "open with" targets.
///
/// macOS only routes web documents through us (`public.html` / `public.xhtml`),
/// so PDF stays out — Preview.app is the canonical viewer there. On Windows
/// the .pdf association is part of the same `RegisteredApplications` entry
/// browsers use, so we accept it.
Set<String> get kLocalFileWebExtensions {
  if (Platform.isWindows) {
    return const {'.html', '.htm', '.xhtml', '.shtml', '.mhtml', '.pdf'};
  }
  return const {'.html', '.htm', '.xhtml'};
}

/// Validates an inbound "open file" target and returns the canonical absolute
/// path on success, or `null` to drop the event. Accepts:
/// - `file://` URLs (macOS Finder "Open With", Windows shell extensions),
/// - native absolute paths (Windows `C:\…`, POSIX `/…`).
///
/// Validation: must exist as a regular file and have an extension in
/// [kLocalFileWebExtensions]. Symlinks are resolved. Callers must never echo
/// the raw input back to the user — see [redactPath].
String? resolveLocalWebFile(String raw) {
  final path = _toFilesystemPath(raw);
  if (path == null) return null;

  final ext = _extension(path);
  if (!kLocalFileWebExtensions.contains(ext)) return null;

  final file = File(path);
  if (!file.existsSync()) return null;

  // Resolve symlinks so the browser doesn't follow a link to an unexpected
  // location and so logs stay deterministic.
  try {
    return file.resolveSymbolicLinksSync();
  } on FileSystemException {
    return null;
  }
}

/// Converts a `file://` URL or a Windows native absolute path to a
/// filesystem path. Returns `null` for anything else (POSIX bare paths are
/// not expected inbound — macOS hands us `file://` URLs).
String? _toFilesystemPath(String raw) {
  if (raw.startsWith('file://')) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'file') return null;
    try {
      return uri.toFilePath();
    } on UnsupportedError {
      return null;
    }
  }

  if (Platform.isWindows && _windowsAbsPath.hasMatch(raw)) return raw;
  return null;
}

final RegExp _windowsAbsPath = RegExp(r'^[a-zA-Z]:[\\/]');

String _extension(String path) {
  // Use both separators — Windows shell sometimes hands us forward slashes.
  final lastSep = path.lastIndexOf(RegExp(r'[\\/]'));
  final name = lastSep >= 0 ? path.substring(lastSep + 1) : path;
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return '';
  return name.substring(dot).toLowerCase();
}

/// Returns true when the inbound string looks like a local file target —
/// either a `file://` URL or a native absolute path. Used by the inbound
/// dispatcher to branch before validation.
bool looksLikeLocalFile(String raw) {
  if (raw.startsWith('file://')) return true;
  if (Platform.isWindows && _windowsAbsPath.hasMatch(raw)) return true;
  return false;
}

/// Redacts a filesystem path for logging — keeps only the basename and a
/// shortened parent (`…/parent/file.html`). Avoids leaking `$HOME` and
/// project-internal paths into shared diagnostic bundles.
String redactPath(String path) {
  // Split on either separator so the helper is OS-agnostic.
  final parts = path.split(RegExp(r'[\\/]')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '<empty>';
  if (parts.length == 1) return '…/${parts.last}';
  return '…/${parts[parts.length - 2]}/${parts.last}';
}
