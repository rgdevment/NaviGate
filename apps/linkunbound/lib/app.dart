import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'l10n/app_localizations.dart';
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
  /// Timestamp when the current picker session became visible. Used to ignore
  /// the spurious blur events that fire while the LSUIElement window is still
  /// in the process of becoming key on macOS.
  DateTime? _pickerShownAt;

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
  void onWindowBlur() {
    final mode = ref.read(appStateProvider).mode;
    if (mode != AppMode.picker) return;
    final shownAt = _pickerShownAt;
    if (shownAt == null) return;
    // Ignore blur bursts within the first ~400 ms of showing the picker —
    // those come from the window not yet being key, not from a real focus
    // change by the user.
    if (DateTime.now().difference(shownAt) < const Duration(milliseconds: 400)) {
      return;
    }
    ref.read(appStateProvider.notifier).hide();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final locale = ref.watch(localeProvider);

    // Show window after the new widget has been painted, not before.
    ref.listen<AppState>(appStateProvider, (prev, next) {
      if (prev?.mode == next.mode) return;
      if (next.mode == AppMode.picker) {
        _pickerShownAt = DateTime.now();
      } else {
        _pickerShownAt = null;
      }
      if (next.mode == AppMode.hidden) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await windowManager.show();
        await windowManager.focus();
      });
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: switch (appState.mode) {
        AppMode.hidden => const ColoredBox(color: Color(0xFF1E1E2E)),
        AppMode.settings => const SettingsWindow(),
        AppMode.picker => PickerWindow(url: appState.pendingUrl ?? ''),
      },
    );
  }
}
