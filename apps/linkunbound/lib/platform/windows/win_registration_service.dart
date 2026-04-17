import 'dart:ffi';

import 'package:logging/logging.dart';
import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:win32_registry/win32_registry.dart';

final _log = Logger('WinRegistrationService');

typedef _SHChangeNotifyNative =
    Void Function(
      Int32 wEventId,
      Uint32 uFlags,
      Pointer<Void> dwItem1,
      Pointer<Void> dwItem2,
    );
typedef _SHChangeNotifyDart =
    void Function(
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

    _log.info('Registered LinkUnbound as browser handler');
  }

  @override
  Future<void> unregister() async {
    _deleteKeyTree(r'Software\Classes\LinkUnboundURL');
    _deleteKeyTree(r'Software\Clients\StartMenuInternet\LinkUnbound');
    _deleteKeyTree(r'Software\LinkUnbound');
    _removeRegisteredApplication();
    _notifyShell();

    _log.info('Unregistered LinkUnbound from browser handlers');
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
      return progId == 'LinkUnboundURL';
    } on Exception {
      return false;
    }
  }

  @override
  Future<Set<String>> get defaultAssociations async {
    final result = <String>{};
    for (final entry in _userChoicePaths.entries) {
      try {
        final key = Registry.openPath(
          RegistryHive.currentUser,
          path: entry.value,
        );
        final progId = key.getValueAsString('ProgId');
        key.close();
        if (progId == 'LinkUnboundURL') result.add(entry.key);
      } on Exception {
        // Not set as default for this association.
      }
    }
    return result;
  }

  static const _userChoicePaths = {
    'http':
        r'Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice',
    'https':
        r'Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice',
    '.htm':
        r'Software\Microsoft\Windows\Shell\Associations\FileExts\.htm\UserChoice',
    '.html':
        r'Software\Microsoft\Windows\Shell\Associations\FileExts\.html\UserChoice',
    '.pdf':
        r'Software\Microsoft\Windows\Shell\Associations\FileExts\.pdf\UserChoice',
  };

  void _writeProgId(String exe, String quotedExe) {
    final root = Registry.openPath(
      RegistryHive.currentUser,
      path: r'Software\Classes',
      desiredAccessRights: AccessRights.allAccess,
    );

    final progId = root.createKey('LinkUnboundURL');
    progId.createValue(
      const RegistryValue('', RegistryValueType.string, 'LinkUnbound URL'),
    );
    progId.createValue(
      const RegistryValue(
        'FriendlyTypeName',
        RegistryValueType.string,
        'LinkUnbound URL',
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
        'LinkUnbound',
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

    final key = root.createKey('LinkUnbound');
    key.createValue(
      const RegistryValue('', RegistryValueType.string, 'LinkUnbound'),
    );

    final defaultIcon = key.createKey('DefaultIcon');
    defaultIcon.createValue(
      RegistryValue('', RegistryValueType.string, '$quotedExe,0'),
    );
    defaultIcon.close();

    final command = key.createKey(r'shell\open\command');
    command.createValue(RegistryValue('', RegistryValueType.string, quotedExe));
    command.close();

    final installInfo = key.createKey('InstallInfo');
    installInfo.createValue(
      RegistryValue('ReinstallCommand', RegistryValueType.string, quotedExe),
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

    final caps = root.createKey(r'LinkUnbound\Capabilities');
    caps.createValue(
      const RegistryValue(
        'ApplicationName',
        RegistryValueType.string,
        'LinkUnbound',
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
        'LinkUnbound',
      ),
    );
    startMenu.close();

    final urlAssoc = caps.createKey('URLAssociations');
    urlAssoc.createValue(
      const RegistryValue('http', RegistryValueType.string, 'LinkUnboundURL'),
    );
    urlAssoc.createValue(
      const RegistryValue('https', RegistryValueType.string, 'LinkUnboundURL'),
    );
    urlAssoc.close();

    final fileAssoc = caps.createKey('FileAssociations');
    for (final ext in [
      '.htm',
      '.html',
      '.pdf',
      '.mhtml',
      '.mht',
      '.shtml',
      '.xhtml',
      '.xht',
      '.svg',
      '.webp',
    ]) {
      fileAssoc.createValue(
        RegistryValue(ext, RegistryValueType.string, 'LinkUnboundURL'),
      );
    }
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
        'LinkUnbound',
        RegistryValueType.string,
        r'Software\LinkUnbound\Capabilities',
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
      key.deleteValue('LinkUnbound');
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
    final shChangeNotify = shell32
        .lookupFunction<_SHChangeNotifyNative, _SHChangeNotifyDart>(
          'SHChangeNotify',
        );
    shChangeNotify(_shcneAssocChanged, _shcnfIdList, nullptr, nullptr);
  }
}
