import 'dart:io';

import 'package:flutter/widgets.dart';

import 'bootstrap.dart';
import 'platform/windows/windows_bindings.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS) {
    throw UnimplementedError('macOS bindings not yet implemented');
  }

  final bindings = await WindowsBindings.create(args);
  await bootstrap(bindings, args);
}
