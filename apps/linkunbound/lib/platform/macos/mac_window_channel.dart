import 'package:flutter/services.dart';

class MacWindowChannel {
  static const _channel = MethodChannel('linkunbound/window');

  Future<void> setPickerMode() => _channel.invokeMethod<void>('setPickerMode');

  Future<void> setSettingsMode() =>
      _channel.invokeMethod<void>('setSettingsMode');

  Future<void> activate() => _channel.invokeMethod<void>('activate');
}
