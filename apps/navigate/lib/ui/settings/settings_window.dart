import 'package:flutter/material.dart';

import 'settings_view.dart';

class SettingsWindow extends StatelessWidget {
  const SettingsWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SettingsView());
  }
}
