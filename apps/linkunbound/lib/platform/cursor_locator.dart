import 'dart:ui' show Offset;

import 'package:screen_retriever/screen_retriever.dart';

abstract interface class CursorLocator {
  Future<(double, double)> cursorPosition();

  Future<(double, double)> screenSize();
}

final class ScreenRetrieverCursorLocator implements CursorLocator {
  const ScreenRetrieverCursorLocator();

  @override
  Future<(double, double)> cursorPosition() async {
    final Offset point = await screenRetriever.getCursorScreenPoint();
    return (point.dx, point.dy);
  }

  @override
  Future<(double, double)> screenSize() async {
    final display = await screenRetriever.getPrimaryDisplay();
    final size = display.visibleSize ?? display.size;
    return (size.width, size.height);
  }
}
