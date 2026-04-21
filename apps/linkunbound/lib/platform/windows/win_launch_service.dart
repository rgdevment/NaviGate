import 'dart:io';

import 'package:linkunbound_core/linkunbound_core.dart';

final class WinLaunchService implements LaunchService {
  @override
  Future<void> launch(
    String executablePath,
    String url,
    List<String> extraArgs,
  ) async {
    final args = [...extraArgs, url];
    await Process.start(executablePath, args, mode: ProcessStartMode.detached);
  }
}
