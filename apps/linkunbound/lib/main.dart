import 'dart:io';

import 'package:flutter/widgets.dart';

import 'bootstrap.dart';
import 'platform/macos/macos_bindings.dart';
import 'platform/platform_bindings.dart';
import 'platform/windows/windows_bindings.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final PlatformBindings bindings;
  if (Platform.isMacOS) {
    bindings = await MacOsBindings.create();
  } else {
    bindings = await WindowsBindings.create(args);
  }

  await bootstrap(bindings, args);
}
