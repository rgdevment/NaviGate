import 'dart:io';

import 'package:flutter/services.dart';
import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:logging/logging.dart';

final _log = Logger('MacIconExtractor');

class MacIconExtractor implements IconExtractor {
  static const _channel = MethodChannel('linkunbound/icon_extractor');

  @override
  Future<String> extractIcon(String executablePath, String outputPath) async {
    if (await File(outputPath).exists()) return outputPath;
    try {
      final result = await _channel.invokeMethod<String>('extract', {
        'appPath': executablePath,
        'outputPath': outputPath,
      });
      return result ?? outputPath;
    } on PlatformException catch (e, st) {
      _log.warning('Icon extraction failed for $executablePath', e, st);
      return outputPath;
    }
  }
}
