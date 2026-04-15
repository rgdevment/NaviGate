import 'package:logging/logging.dart';
import 'package:navigate_core/navigate_core.dart';
import 'package:win32_registry/win32_registry.dart';

final _log = Logger('WinBrowserDetector');

final class WinBrowserDetector implements BrowserDetector {
  @override
  Future<List<Browser>> detect() async {
    final browsers = <String, Browser>{};

    for (final hive in [RegistryHive.localMachine, RegistryHive.currentUser]) {
      _scanHive(hive, browsers);
    }

    _log.info('Detected ${browsers.length} browsers');
    return browsers.values.toList();
  }

  void _scanHive(RegistryHive hive, Map<String, Browser> browsers) {
    final RegistryKey root;
    try {
      root = Registry.openPath(
        hive,
        path: r'Software\Clients\StartMenuInternet',
      );
    } on Exception {
      return;
    }

    try {
      for (final name in root.subkeyNames) {
        if (name == 'NaviGate') continue;
        if (browsers.containsKey(name.toLowerCase())) continue;

        try {
          final browser = _readBrowser(hive, name);
          if (browser != null) {
            browsers[name.toLowerCase()] = browser;
          }
        } on Exception catch (e) {
          _log.warning('Failed to read browser $name: $e');
        }
      }
    } finally {
      root.close();
    }
  }

  Browser? _readBrowser(RegistryHive hive, String name) {
    final basePath = 'Software\\Clients\\StartMenuInternet\\$name';
    final key = Registry.openPath(hive, path: basePath);

    try {
      final displayName =
          key.getValueAsString('') ?? key.getValueAsString('(Default)') ?? name;

      final commandKey = Registry.openPath(
        hive,
        path: '$basePath\\shell\\open\\command',
      );
      final rawCommand = commandKey.getValueAsString('') ?? '';
      commandKey.close();

      final executablePath = _extractExePath(rawCommand);
      if (executablePath.isEmpty) return null;

      final id = _generateId(name);

      String iconPath = '';
      try {
        final iconKey = Registry.openPath(
          hive,
          path: '$basePath\\DefaultIcon',
        );
        iconPath = _extractIconPath(iconKey.getValueAsString('') ?? '');
        iconKey.close();
      } on Exception {
        iconPath = executablePath;
      }

      return Browser(
        id: id,
        name: displayName,
        executablePath: executablePath,
        iconPath: iconPath,
      );
    } finally {
      key.close();
    }
  }

  String _extractExePath(String rawCommand) {
    final trimmed = rawCommand.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('"')) {
      final end = trimmed.indexOf('"', 1);
      if (end < 0) return trimmed.substring(1);
      return trimmed.substring(1, end);
    }

    final exeIndex = trimmed.toLowerCase().indexOf('.exe');
    if (exeIndex > 0) return trimmed.substring(0, exeIndex + 4);

    final spaceIndex = trimmed.indexOf(' ');
    if (spaceIndex < 0) return trimmed;
    return trimmed.substring(0, spaceIndex);
  }

  String _extractIconPath(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('"')) {
      final end = trimmed.indexOf('"', 1);
      if (end < 0) return trimmed.substring(1);
      return trimmed.substring(1, end);
    }

    final commaIndex = trimmed.lastIndexOf(',');
    if (commaIndex > 0) return trimmed.substring(0, commaIndex).trim();
    return trimmed;
  }

  String _generateId(String registryName) => registryName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
