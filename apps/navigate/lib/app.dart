import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'providers.dart';
import 'ui/picker/picker_window.dart';
import 'ui/settings/settings_window.dart';
import 'ui/shared/app_theme.dart';

final class NavigateApp extends ConsumerStatefulWidget {
  const NavigateApp({super.key});

  @override
  ConsumerState<NavigateApp> createState() => _NavigateAppState();
}

final class _NavigateAppState extends ConsumerState<NavigateApp>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
    ref.read(appStateProvider.notifier).hide();
  }

  @override
  void onWindowFocus() {
    ref.invalidate(isDefaultBrowserProvider);
    ref.invalidate(isStartupEnabledProvider);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: switch (appState.mode) {
        AppMode.hidden => const SizedBox.shrink(),
        AppMode.settings => const SettingsWindow(),
        AppMode.picker => PickerWindow(url: appState.pendingUrl ?? ''),
      },
    );
  }
}
