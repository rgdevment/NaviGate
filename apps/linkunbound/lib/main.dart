import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'bootstrap.dart';
import 'platform/macos/macos_bindings.dart';
import 'platform/platform_bindings.dart';
import 'platform/windows/windows_bindings.dart';

Future<void> main(List<String> args) async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        _writeStartupCrashLog('FlutterError', details.exception, details.stack);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        _writeStartupCrashLog('PlatformDispatcher', error, stack);
        return true;
      };

      final PlatformBindings bindings;
      if (Platform.isMacOS) {
        bindings = await MacOsBindings.create();
      } else {
        bindings = await WindowsBindings.create(args);
      }

      await bootstrap(bindings, args);
    },
    (error, stack) {
      _writeStartupCrashLog('runZonedGuarded', error, stack);
    },
  );
}

void _writeStartupCrashLog(String source, Object error, StackTrace? stack) {
  try {
    final String base;
    if (Platform.isWindows) {
      base =
          Platform.environment['APPDATA'] ??
          Platform.environment['LOCALAPPDATA'] ??
          '${Platform.environment['USERPROFILE'] ?? Directory.systemTemp.path}\\AppData\\Roaming';
    } else {
      base =
          '${Platform.environment['HOME'] ?? Directory.systemTemp.path}/Library/Application Support';
    }
    final dir = Platform.isWindows ? '$base\\LinkUnbound' : '$base/LinkUnbound';
    Directory(dir).createSync(recursive: true);
    final file = File('$dir${Platform.pathSeparator}startup_crash.log');
    final now = DateTime.now().toIso8601String();
    file.writeAsStringSync(
      '[$now] $source: $error\n$stack\n\n',
      mode: FileMode.append,
    );
  } on Object {
    // Best-effort crash log; ignore secondary failures.
  }
}
