import 'package:flutter/services.dart';

/// Thin Dart bridge over `linkunbound/window` — used by `bootstrap.dart` on
/// macOS to switch the shared NSWindow between picker and settings layouts
/// (traffic-light visibility, resizability, window level).
class MacWindowChannel {
  static const _channel = MethodChannel('linkunbound/window');

  Future<void> setPickerMode() => _channel.invokeMethod<void>('setPickerMode');

  Future<void> setSettingsMode() =>
      _channel.invokeMethod<void>('setSettingsMode');
}
