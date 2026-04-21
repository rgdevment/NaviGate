import 'package:logging/logging.dart';
import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:win32_registry/win32_registry.dart';

import 'win_package_context.dart';

final _log = Logger('WinStartupService');

const _runKeyPath = r'Software\Microsoft\Windows\CurrentVersion\Run';
const _valueName = 'LinkUnbound';

final class WinStartupService implements StartupService {
  @override
  Future<void> enable(String executablePath) async {
    if (isRunningInMsix()) {
      // Startup in MSIX is declared via the manifest StartupTask; HKCU\Run is
      // virtualized and the user toggles it from Windows Settings > Startup.
      return;
    }
    final key = Registry.openPath(
      RegistryHive.currentUser,
      path: _runKeyPath,
      desiredAccessRights: AccessRights.allAccess,
    );
    key.createValue(
      RegistryValue(
        _valueName,
        RegistryValueType.string,
        '"${executablePath.replaceAll('/', '\\')}" --background',
      ),
    );
    key.close();
  }

  @override
  Future<void> disable() async {
    if (isRunningInMsix()) {
      return;
    }
    try {
      final key = Registry.openPath(
        RegistryHive.currentUser,
        path: _runKeyPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      key.deleteValue(_valueName);
      key.close();
    } on Exception {
      _log.fine('Run key not found during disable');
    }
  }

  @override
  Future<bool> get isEnabled async {
    if (isRunningInMsix()) {
      // Manifest declares enabled=true by default; the user can disable it
      // from Windows Settings but we cannot read that state from Dart, so we
      // surface the declared default. Toggling in-app is a no-op (see above).
      return true;
    }
    try {
      final key = Registry.openPath(
        RegistryHive.currentUser,
        path: _runKeyPath,
      );
      final value = key.getValueAsString(_valueName);
      key.close();
      return value != null && value.isNotEmpty;
    } on Exception {
      return false;
    }
  }
}
