import 'package:flutter/services.dart';
import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:logging/logging.dart';

final _log = Logger('MacRegistrationService');

class MacRegistrationService implements RegistrationService {
  static const _channel = MethodChannel('linkunbound/registration');

  @override
  Future<void> register(String executablePath) async {
    await _channel.invokeMethod<void>('register');
  }

  @override
  Future<void> unregister() async {
    await _channel.invokeMethod<void>('unregister');
  }

  @override
  Future<bool> get isDefault async {
    try {
      final result = await _channel.invokeMethod<bool>('isDefault');
      return result ?? false;
    } on PlatformException catch (e, st) {
      _log.warning('isDefault check failed', e, st);
      return false;
    }
  }

  @override
  Future<Set<String>> get defaultAssociations async {
    try {
      final list = await _channel.invokeListMethod<String>(
        'defaultAssociations',
      );
      return (list ?? const <String>[]).toSet();
    } on PlatformException catch (e, st) {
      _log.warning('defaultAssociations failed', e, st);
      return const <String>{};
    }
  }
}
