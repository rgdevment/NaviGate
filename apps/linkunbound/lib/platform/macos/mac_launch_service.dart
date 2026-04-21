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
    final args = <String>['-a', executablePath];
    if (extraArgs.isNotEmpty) {
      args.addAll(['--args', ...extraArgs, url]);
    } else {
      args.add(url);
    }
    await Process.start('/usr/bin/open', args, mode: ProcessStartMode.detached);
  }
}
