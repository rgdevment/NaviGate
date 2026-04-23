import 'package:flutter/services.dart';

enum MsixStartupTaskState {
  disabled,
  disabledByUser,
  disabledByPolicy,
  enabled,
  enabledByPolicy,
  unknown,
}

class MsixStartupTask {
  const MsixStartupTask._();

  static const _channel = MethodChannel('linkunbound/startup_task');

  static MsixStartupTaskState _parse(String? raw) {
    switch (raw) {
      case 'disabled':
        return MsixStartupTaskState.disabled;
      case 'disabledByUser':
        return MsixStartupTaskState.disabledByUser;
      case 'disabledByPolicy':
        return MsixStartupTaskState.disabledByPolicy;
      case 'enabled':
        return MsixStartupTaskState.enabled;
      case 'enabledByPolicy':
        return MsixStartupTaskState.enabledByPolicy;
    }
    return MsixStartupTaskState.unknown;
  }

  static Future<MsixStartupTaskState> getState() async {
    final res = await _channel.invokeMethod<String>('getState');
    return _parse(res);
  }

  static Future<MsixStartupTaskState> enable() async {
    final res = await _channel.invokeMethod<String>('enable');
    return _parse(res);
  }

  static Future<MsixStartupTaskState> disable() async {
    final res = await _channel.invokeMethod<String>('disable');
    return _parse(res);
  }
}
