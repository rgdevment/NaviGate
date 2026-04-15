import 'package:navigate_core/navigate_core.dart';

final class WinStartupService implements StartupService {
  @override
  Future<void> enable(String executablePath) {
    throw UnimplementedError();
  }

  @override
  Future<void> disable() {
    throw UnimplementedError();
  }

  @override
  Future<bool> get isEnabled {
    throw UnimplementedError();
  }
}
