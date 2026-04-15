import 'package:logging/logging.dart';
import 'package:navigate_core/navigate_core.dart';
import 'package:win32_registry/win32_registry.dart';

final _log = Logger('WinStartupService');

const _runKeyPath = r'Software\Microsoft\Windows\CurrentVersion\Run';
const _valueName = 'LinkUnbound';

final class WinStartupService implements StartupService {
  @override
  Future<void> enable(String executablePath) async {
    final key = Registry.openPath(
      RegistryHive.currentUser,
      path: _runKeyPath,
      desiredAccessRights: AccessRights.allAccess,
    );
    key.createValue(
      RegistryValue(
        _valueName,
        RegistryValueType.string,
        '"${executablePath.replaceAll('/', '\\')}"',
      ),
    );
    key.close();
    _log.info('Startup enabled');
  }

  @override
  Future<void> disable() async {
    try {
      final key = Registry.openPath(
        RegistryHive.currentUser,
        path: _runKeyPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      key.deleteValue(_valueName);
      key.close();
      _log.info('Startup disabled');
    } on Exception {
      _log.fine('Run key not found during disable');
    }
  }

  @override
  Future<bool> get isEnabled async {
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
