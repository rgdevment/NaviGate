import 'dart:io';

import 'package:linkunbound_core/linkunbound_core.dart';

/// Launches a browser via `/usr/bin/open`.
///
/// `executablePath` is the absolute path to the `.app` bundle (as returned by
/// `MacBrowserDetector`). `extraArgs` are forwarded as program arguments via
/// `--args`. The child process is detached so closing LinkUnbound does not kill
/// the browser.
class MacLaunchService implements LaunchService {
  @override
  Future<void> launch(
    String executablePath,
    String url,
    List<String> extraArgs,
  ) async {
    // `open` requires the document/URL BEFORE `--args`; everything after
    // `--args` is forwarded as argv to the launched app.
    final args = <String>['-a', executablePath, url];
    if (extraArgs.isNotEmpty) {
      args.add('--args');
      args.addAll(extraArgs);
    }
    await Process.start('/usr/bin/open', args, mode: ProcessStartMode.detached);
  }
}
