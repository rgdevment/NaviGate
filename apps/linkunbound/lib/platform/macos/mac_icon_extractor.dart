import 'dart:io';

import 'package:flutter/services.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

class MacIconExtractor implements IconExtractor {
  static const _channel = MethodChannel('linkunbound/icon_extractor');

  @override
  Future<String> extractIcon(String executablePath, String outputPath) async {
    if (await File(outputPath).exists()) return outputPath;
    final result = await _channel.invokeMethod<String>('extract', {
      'appPath': executablePath,
      'outputPath': outputPath,
    });
    return result ?? outputPath;
  }
}
