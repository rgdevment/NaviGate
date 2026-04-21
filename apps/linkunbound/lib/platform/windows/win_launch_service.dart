import 'dart:io';

import 'package:logging/logging.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

import '../local_file_url.dart';

final _log = Logger('WinLaunchService');

final class WinLaunchService implements LaunchService {
  @override
  Future<void> launch(
    String executablePath,
    String url,
    List<String> extraArgs,
  ) async {
    final args = [...extraArgs, url];
    _log.info(
      'Launching ${redactPath(executablePath)} with '
      '${extraArgs.length} extra arg(s), target=${_redactTarget(url)}',
    );
    await Process.start(executablePath, args, mode: ProcessStartMode.detached);
  }

  String _redactTarget(String url) {
    if (looksLikeLocalFile(url)) {
      if (url.startsWith('file://')) {
        try {
          return 'file://${redactPath(Uri.parse(url).toFilePath())}';
        } on Exception {
          return 'file://<unparseable>';
        }
      }
      return redactPath(url);
    }
    return url;
  }
}
