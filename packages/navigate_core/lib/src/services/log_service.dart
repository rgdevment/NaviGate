import 'dart:io';

import 'package:logging/logging.dart';

const _maxLogSize = 2 * 1024 * 1024; // 2 MB

void initLogging(File logFile) {
  logFile.parent.createSync(recursive: true);
  _rotateIfNeeded(logFile);

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    final line =
        '${record.time.toIso8601String()} '
        '[${record.level.name}] '
        '${record.loggerName}: '
        '${record.message}'
        '${record.error != null ? '\n  ${record.error}' : ''}'
        '${record.stackTrace != null ? '\n  ${record.stackTrace}' : ''}';
    stderr.writeln(line);
    logFile.writeAsStringSync('$line\n', mode: FileMode.append);
  });
}

void _rotateIfNeeded(File logFile) {
  if (!logFile.existsSync()) return;
  if (logFile.lengthSync() < _maxLogSize) return;

  final backup = File('${logFile.path}.1');
  if (backup.existsSync()) backup.deleteSync();
  logFile.renameSync(backup.path);
}
