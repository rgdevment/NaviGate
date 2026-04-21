import 'package:flutter/services.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

class MacBrowserDetector implements BrowserDetector {
  static const _channel = MethodChannel('linkunbound/browser_detector');

  @override
  Future<List<Browser>> detect() async {
    final raw = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
      'detect',
    );
    if (raw == null) return const [];
    return raw
        .map((entry) {
          final m = entry.cast<String, dynamic>();
          return Browser(
            id: m['id'] as String,
            name: m['name'] as String,
            executablePath: m['executablePath'] as String,
            iconPath: '',
          );
        })
        .toList(growable: false);
  }
}
