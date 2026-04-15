import 'dart:io';

import 'package:logging/logging.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

final _log = Logger('WinLaunchService');

final class WinLaunchService implements LaunchService {
  @override
  Future<void> launch(
    String executablePath,
    String url,
    List<String> extraArgs,
  ) async {
    final args = [...extraArgs, url];
    _log.info('Launching $executablePath with args: $args');
    await Process.start(executablePath, args, mode: ProcessStartMode.detached);
  }
}
