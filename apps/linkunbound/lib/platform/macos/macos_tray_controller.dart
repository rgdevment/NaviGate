import 'dart:ui' show VoidCallback;

import 'package:tray_manager/tray_manager.dart' as tm;

import '../tray_controller.dart';

/// macOS implementation of [TrayController] using the `tray_manager` package.
///
/// Menu bar idiom:
/// - **Left click** on the icon → invokes the activation callback (Settings).
/// - **Right click** on the icon → shows the context menu.
///
/// On macOS the context menu is NOT attached to `NSStatusItem.menu`, so both
/// clicks are delivered to the Flutter side via `TrayListener` callbacks and
/// we explicitly call `popUpContextMenu()` on right click.
final class MacOsTrayController implements TrayController, tm.TrayListener {
  VoidCallback? _onActivated;
  bool _listenerAttached = false;

  @override
  Future<void> init({
    required String title,
    required String iconPath,
    required String tooltip,
  }) async {
    if (!_listenerAttached) {
      tm.trayManager.addListener(this);
      _listenerAttached = true;
    }

    // The bundled icon is a white silhouette (template), so let macOS auto-tint
    // it for light/dark menu bar appearance.
    await tm.trayManager.setIcon(iconPath, isTemplate: true);
    await tm.trayManager.setToolTip(tooltip);
  }

  @override
  Future<void> setMenu(List<TrayMenuItem> items) async {
    final menu = tm.Menu(
      items: [
        for (final item in items)
          if (item.isSeparator)
            tm.MenuItem.separator()
          else
            tm.MenuItem(
              label: item.label!,
              onClick: (_) => item.onClick?.call(),
            ),
      ],
    );
    await tm.trayManager.setContextMenu(menu);
  }

  @override
  void onActivated(VoidCallback callback) {
    _onActivated = callback;
  }

  @override
  Future<void> dispose() async {
    if (_listenerAttached) {
      tm.trayManager.removeListener(this);
      _listenerAttached = false;
    }
    await tm.trayManager.destroy();
  }

  // --- TrayListener -----------------------------------------------------

  @override
  void onTrayIconMouseDown() => _onActivated?.call();

  @override
  void onTrayIconMouseUp() {}

  @override
  void onTrayIconRightMouseDown() {
    tm.trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  void onTrayMenuItemClick(tm.MenuItem menuItem) {}
}
