import 'dart:io';

import 'package:logging/logging.dart';
import 'package:win32_registry/win32_registry.dart';

final _log = Logger('DiagnosticsService');

const _maxLogLines = 200;

const _registryPaths = [
  r'Software\Classes\LinkUnboundURL',
  r'Software\Clients\StartMenuInternet\LinkUnbound',
  r'Software\LinkUnbound',
  r'Software\RegisteredApplications',
  r'Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice',
  r'Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice',
];

Future<String> exportDiagnostics({
  required Directory appDataDir,
  required String appVersion,
}) async {
  final timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .split('.')
      .first;
  final staging = await Directory.systemTemp.createTemp('lu_diag_');

  try {
    _writeSystemInfo(staging, appDataDir, appVersion);
    _writeRegistryDump(staging);
    _copyLogTail(appDataDir, staging);

    final zipPath = '${appDataDir.path}\\linkunbound-diag-$timestamp.zip';

    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      'Compress-Archive'
          ' -Path "${staging.path}\\*"'
          ' -DestinationPath "$zipPath"'
          ' -Force',
    ]);

    if (result.exitCode != 0) {
      _log.warning('Compress-Archive failed: ${result.stderr}');
      throw Exception('Compress-Archive failed: ${result.stderr}');
    }

    await Process.run('explorer.exe', ['/select,$zipPath']);

    return zipPath;
  } on Exception catch (e) {
    _log.warning('Diagnostics export failed: $e');
    rethrow;
  } finally {
    try {
      if (staging.existsSync()) await staging.delete(recursive: true);
    } on Exception catch (e) {
      _log.fine('Failed to clean staging dir: $e');
    }
  }
}

void _writeSystemInfo(
  Directory staging,
  Directory appDataDir,
  String appVersion,
) {
  final buf = StringBuffer()
    ..writeln('LinkUnbound Diagnostics Report')
    ..writeln('Generated: ${DateTime.now().toIso8601String()}')
    ..writeln()
    ..writeln('--- System ---')
    ..writeln('OS: ${Platform.operatingSystemVersion}')
    ..writeln('Locale: ${Platform.localeName}')
    ..writeln()
    ..writeln('--- Application ---')
    ..writeln('Version: $appVersion')
    ..writeln('Executable: ${Platform.resolvedExecutable}')
    ..writeln('Data: ${appDataDir.path}')
    ..writeln()
    ..writeln('--- Data Files ---');

  try {
    if (appDataDir.existsSync()) {
      for (final entity in appDataDir.listSync()) {
        final name = entity.path.split('\\').last;
        if (entity is File) {
          buf.writeln('  $name (${entity.lengthSync()} bytes)');
        } else if (entity is Directory) {
          buf.writeln('  $name/');
        }
      }
    }
  } on Exception catch (e) {
    buf.writeln('  <error listing files: $e>');
  }

  File('${staging.path}\\system_info.txt').writeAsStringSync(buf.toString());
}

void _writeRegistryDump(Directory staging) {
  final buf = StringBuffer()
    ..writeln('Registry Dump')
    ..writeln('Generated: ${DateTime.now().toIso8601String()}')
    ..writeln();

  for (final path in _registryPaths) {
    _dumpKey(path, buf);
    buf.writeln();
  }

  File('${staging.path}\\registry.txt').writeAsStringSync(buf.toString());
}

void _dumpKey(String path, StringBuffer buf, {int depth = 0}) {
  final indent = '  ' * depth;
  try {
    final key = Registry.openPath(RegistryHive.currentUser, path: path);

    buf.writeln('$indent[HKCU\\$path]');
    for (final v in key.values) {
      final name = v.name.isEmpty ? '(Default)' : v.name;
      try {
        buf.writeln('$indent  $name = ${v.data} [${v.type}]');
      } on Exception {
        buf.writeln('$indent  $name = <unreadable> [${v.type}]');
      }
    }

    final subkeys = key.subkeyNames.toList();
    key.close();

    for (final sub in subkeys) {
      _dumpKey('$path\\$sub', buf, depth: depth + 1);
    }
  } on Exception {
    buf.writeln('$indent[HKCU\\$path] — not found');
  }
}

void _copyLogTail(Directory appDataDir, Directory staging) {
  final logFile = File('${appDataDir.path}\\navigate.log');
  if (!logFile.existsSync()) return;

  try {
    final lines = logFile.readAsLinesSync();
    final tail = lines.length > _maxLogLines
        ? lines.sublist(lines.length - _maxLogLines)
        : lines;

    File('${staging.path}\\navigate.log').writeAsStringSync(tail.join('\n'));
  } on Exception catch (e) {
    File(
      '${staging.path}\\navigate.log',
    ).writeAsStringSync('<error reading log: $e>');
  }
}
