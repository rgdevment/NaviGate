import 'dart:io';

/// Detects whether the running process is packaged in an MSIX container.
/// MSIX apps run from `...\WindowsApps\...` and expose the `APPX_PACKAGE_FULL_NAME`
/// environment variable via the package identity.
bool isRunningInMsix() {
  if (!Platform.isWindows) return false;
  if (Platform.environment.containsKey('APPX_PACKAGE_FULL_NAME')) return true;
  final exe = Platform.resolvedExecutable.toLowerCase();
  return exe.contains(r'\windowsapps\');
}
