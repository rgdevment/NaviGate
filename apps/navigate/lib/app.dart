import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'providers.dart';

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
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: switch (appState.mode) {
        AppMode.hidden => const SizedBox.shrink(),
        AppMode.settings => const Scaffold(
          body: Center(child: Text('Settings — Phase 4')),
        ),
        AppMode.picker => Scaffold(
          body: Center(
            child: Text('Picker: ${appState.pendingUrl ?? ""}'),
          ),
        ),
      },
    );
  }
}
