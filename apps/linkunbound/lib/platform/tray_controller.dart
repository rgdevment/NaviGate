import 'dart:ui' show VoidCallback;

abstract interface class TrayController {
  Future<void> init({
    required String title,
    required String iconPath,
    required String tooltip,
  });

  Future<void> setMenu(List<TrayMenuItem> items);

  void onActivated(VoidCallback callback);

  Future<void> dispose();
}

final class TrayMenuItem {
  const TrayMenuItem({this.label, this.onClick, this.isSeparator = false});

  const TrayMenuItem.separator() : label = null, onClick = null, isSeparator = true;

  final String? label;
  final VoidCallback? onClick;
  final bool isSeparator;
}
