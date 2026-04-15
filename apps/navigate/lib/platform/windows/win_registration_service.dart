import 'dart:ffi';

import 'package:logging/logging.dart';
import 'package:navigate_core/navigate_core.dart';
import 'package:win32_registry/win32_registry.dart';

final _log = Logger('WinRegistrationService');

typedef _SHChangeNotifyNative = Void Function(
  Int32 wEventId,
  Uint32 uFlags,
  Pointer<Void> dwItem1,
  Pointer<Void> dwItem2,
);
typedef _SHChangeNotifyDart = void Function(
  int wEventId,
  int uFlags,
  Pointer<Void> dwItem1,
  Pointer<Void> dwItem2,
);

const _shcneAssocChanged = 0x08000000;
const _shcnfIdList = 0x0000;

final class WinRegistrationService implements RegistrationService {
  @override
  Future<void> register(String executablePath) async {
    final exe = executablePath.replaceAll('/', '\\');
    final quotedExe = '"$exe"';

    _writeProgId(exe, quotedExe);
    _writeStartMenuInternet(exe, quotedExe);
    _writeCapabilities(exe, quotedExe);
    _writeRegisteredApplications();
    _notifyShell();

    _log.info('Registered NaviGate as browser handler');
  }

  @override
  Future<void> unregister() async {
    _deleteKeyTree(r'Software\Classes\NaviGateURL');
    _deleteKeyTree(r'Software\Clients\StartMenuInternet\NaviGate');
    _deleteKeyTree(r'Software\NaviGate');
    _removeRegisteredApplication();
    _notifyShell();

    _log.info('Unregistered NaviGate from browser handlers');
  }

  @override
  Future<bool> get isDefault async {
    try {
      final key = Registry.openPath(
        RegistryHive.currentUser,
        path:
            r'Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice',
      );
      final progId = key.getValueAsString('ProgId');
      key.close();
      return progId == 'NaviGateURL';
    } on Exception {
      return false;
    }
  }

  void _writeProgId(String exe, String quotedExe) {
    final root = Registry.openPath(
      RegistryHive.currentUser,
      path: r'Software\Classes',
      desiredAccessRights: AccessRights.allAccess,
    );

    final progId = root.createKey('NaviGateURL');
    progId.createValue(
      const RegistryValue('', RegistryValueType.string, 'NaviGate URL'),
    );
    progId.createValue(
      const RegistryValue(
        'FriendlyTypeName',
        RegistryValueType.string,
        'NaviGate URL',
      ),
    );
    progId.createValue(
      const RegistryValue('EditFlags', RegistryValueType.int32, 2),
    );

    final app = progId.createKey('Application');
    app.createValue(
      const RegistryValue(
        'ApplicationName',
        RegistryValueType.string,
        'NaviGate',
      ),
    );
    app.createValue(
      const RegistryValue(
        'ApplicationDescription',
        RegistryValueType.string,
        'Browser picker for Windows',
      ),
    );
    app.createValue(
      RegistryValue(
        'ApplicationIcon',
        RegistryValueType.string,
        '$quotedExe,0',
      ),
    );
    app.close();

    final defaultIcon = progId.createKey('DefaultIcon');
    defaultIcon.createValue(
      RegistryValue('', RegistryValueType.string, '$quotedExe,0'),
    );
    defaultIcon.close();

    final command = progId.createKey(r'shell\open\command');
    command.createValue(
      RegistryValue('', RegistryValueType.string, '$quotedExe "%1"'),
    );
    command.close();

    progId.close();
    root.close();
  }

  void _writeStartMenuInternet(String exe, String quotedExe) {
    final root = Registry.openPath(
      RegistryHive.currentUser,
      path: r'Software\Clients\StartMenuInternet',
      desiredAccessRights: AccessRights.allAccess,
    );

    final key = root.createKey('NaviGate');
    key.createValue(
      const RegistryValue('', RegistryValueType.string, 'NaviGate'),
    );

    final defaultIcon = key.createKey('DefaultIcon');
    defaultIcon.createValue(
      RegistryValue('', RegistryValueType.string, '$quotedExe,0'),
    );
    defaultIcon.close();

    final command = key.createKey(r'shell\open\command');
    command.createValue(
      RegistryValue('', RegistryValueType.string, quotedExe),
    );
    command.close();

    final installInfo = key.createKey('InstallInfo');
    installInfo.createValue(
      RegistryValue(
        'ReinstallCommand',
        RegistryValueType.string,
        quotedExe,
      ),
    );
    installInfo.createValue(
      const RegistryValue('IconsVisible', RegistryValueType.int32, 1),
    );
    installInfo.close();

    key.close();
    root.close();
  }

  void _writeCapabilities(String exe, String quotedExe) {
    final root = Registry.openPath(
      RegistryHive.currentUser,
      path: r'Software',
      desiredAccessRights: AccessRights.allAccess,
    );

    final caps = root.createKey(r'NaviGate\Capabilities');
    caps.createValue(
      const RegistryValue(
        'ApplicationName',
        RegistryValueType.string,
        'NaviGate',
      ),
    );
    caps.createValue(
      const RegistryValue(
        'ApplicationDescription',
        RegistryValueType.string,
        'Browser picker for Windows',
      ),
    );
    caps.createValue(
      RegistryValue(
        'ApplicationIcon',
        RegistryValueType.string,
        '$quotedExe,0',
      ),
    );

    final startMenu = caps.createKey('Startmenu');
    startMenu.createValue(
      const RegistryValue(
        'StartMenuInternet',
        RegistryValueType.string,
        'NaviGate',
      ),
    );
    startMenu.close();

    final urlAssoc = caps.createKey('URLAssociations');
    urlAssoc.createValue(
      const RegistryValue('http', RegistryValueType.string, 'NaviGateURL'),
    );
    urlAssoc.createValue(
      const RegistryValue('https', RegistryValueType.string, 'NaviGateURL'),
    );
    urlAssoc.close();

    final fileAssoc = caps.createKey('FileAssociations');
    fileAssoc.createValue(
      const RegistryValue('.htm', RegistryValueType.string, 'NaviGateURL'),
    );
    fileAssoc.createValue(
      const RegistryValue('.html', RegistryValueType.string, 'NaviGateURL'),
    );
    fileAssoc.close();

    caps.close();
    root.close();
  }

  void _writeRegisteredApplications() {
    final key = Registry.openPath(
      RegistryHive.currentUser,
      path: r'Software\RegisteredApplications',
      desiredAccessRights: AccessRights.allAccess,
    );
    key.createValue(
      const RegistryValue(
        'NaviGate',
        RegistryValueType.string,
        r'Software\NaviGate\Capabilities',
      ),
    );
    key.close();
  }

  void _removeRegisteredApplication() {
    try {
      final key = Registry.openPath(
        RegistryHive.currentUser,
        path: r'Software\RegisteredApplications',
        desiredAccessRights: AccessRights.allAccess,
      );
      key.deleteValue('NaviGate');
      key.close();
    } on Exception {
      // Value may not exist
    }
  }

  void _deleteKeyTree(String path) {
    try {
      final parent = Registry.openPath(
        RegistryHive.currentUser,
        path: _parentPath(path),
        desiredAccessRights: AccessRights.allAccess,
      );
      parent.deleteKey(_leafName(path), recursive: true);
      parent.close();
    } on Exception catch (e) {
      _log.fine('Key $path not found during unregister: $e');
    }
  }

  String _parentPath(String path) {
    final lastSlash = path.lastIndexOf('\\');
    return lastSlash < 0 ? '' : path.substring(0, lastSlash);
  }

  String _leafName(String path) {
    final lastSlash = path.lastIndexOf('\\');
    return lastSlash < 0 ? path : path.substring(lastSlash + 1);
  }

  void _notifyShell() {
    final shell32 = DynamicLibrary.open('shell32.dll');
    final shChangeNotify =
        shell32.lookupFunction<_SHChangeNotifyNative, _SHChangeNotifyDart>(
          'SHChangeNotify',
        );
    shChangeNotify(_shcneAssocChanged, _shcnfIdList, nullptr, nullptr);
  }
}
