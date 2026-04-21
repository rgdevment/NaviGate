import 'dart:ui' show VoidCallback;

import 'package:system_tray/system_tray.dart';

import '../tray_controller.dart';

final class WindowsTrayController implements TrayController {
  final SystemTray _tray = SystemTray();
  VoidCallback? _onActivated;

  @override
  Future<void> init({
    required String title,
    required String iconPath,
    required String tooltip,
  }) async {
    await _tray.initSystemTray(
      title: title,
      iconPath: iconPath,
      toolTip: tooltip,
    );

    _tray.registerSystemTrayEventHandler((eventName) {
      switch (eventName) {
        case kSystemTrayEventDoubleClick:
          _onActivated?.call();
        case kSystemTrayEventRightClick:
          _tray.popUpContextMenu();
      }
    });
  }

  @override
  Future<void> setMenu(List<TrayMenuItem> items) async {
    final menu = Menu();
    await menu.buildFrom([
      for (final item in items)
        if (item.isSeparator)
          MenuSeparator()
        else
          MenuItemLabel(label: item.label!, onClicked: (_) => item.onClick?.call()),
    ]);
    await _tray.setContextMenu(menu);
  }

  @override
  void onActivated(VoidCallback callback) {
    _onActivated = callback;
  }

  @override
  Future<void> dispose() async {
    await _tray.destroy();
  }
}
