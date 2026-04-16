import 'dart:math';

import 'package:flutter/painting.dart';

final class PickerLayout {
  const PickerLayout._();

  static const double width = 300.0;
  static const double rowHeight = 44.0;
  static const int maxVisible = 6;
  static const double _overhead = 100.0;
  static const double _chromeW = 16.0;
  static const double _chromeH = 9.0;

  static Size windowSize(int browserCount) {
    final visible = min(browserCount, maxVisible);
    final h = _overhead + visible * rowHeight;
    return Size(width + _chromeW, h + _chromeH);
  }
}
