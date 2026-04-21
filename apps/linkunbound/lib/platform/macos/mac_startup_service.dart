import 'package:flutter/services.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

class MacStartupService implements StartupService {
  static const _channel = MethodChannel('linkunbound/startup');

  @override
  Future<void> enable(String executablePath) async {
    await _channel.invokeMethod<void>('enable');
  }

  @override
  Future<void> disable() async {
    await _channel.invokeMethod<void>('disable');
  }

  @override
  Future<bool> get isEnabled async {
    final result = await _channel.invokeMethod<bool>('isEnabled');
    return result ?? false;
  }
}
