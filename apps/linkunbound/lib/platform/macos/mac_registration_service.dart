import 'package:flutter/services.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

class MacRegistrationService implements RegistrationService {
  static const _channel = MethodChannel('linkunbound/registration');

  @override
  Future<void> register(String executablePath) async {
    // executablePath is ignored on macOS — registration is bundle-based.
    await _channel.invokeMethod<void>('register');
  }

  @override
  Future<void> unregister() async {
    await _channel.invokeMethod<void>('unregister');
  }

  @override
  Future<bool> get isDefault async {
    final result = await _channel.invokeMethod<bool>('isDefault');
    return result ?? false;
  }

  @override
  Future<Set<String>> get defaultAssociations async {
    final list = await _channel.invokeListMethod<String>('defaultAssociations');
    return (list ?? const <String>[]).toSet();
  }
}
