import 'package:flutter_test/flutter_test.dart';

import 'package:linkunbound/ui/picker/picker_layout.dart';

void main() {
  group('PickerLayout.windowSize', () {
    test('returns base overhead dimensions for 0 browsers', () {
      final size = PickerLayout.windowSize(0);
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('height grows by rowHeight for each browser up to maxVisible', () {
      final size1 = PickerLayout.windowSize(1);
      final size2 = PickerLayout.windowSize(2);
      expect(
        size2.height - size1.height,
        closeTo(PickerLayout.rowHeight, 0.001),
      );
    });

    test('caps height at maxVisible rows', () {
      final sizeCapped = PickerLayout.windowSize(PickerLayout.maxVisible);
      final sizeOver = PickerLayout.windowSize(PickerLayout.maxVisible + 3);
      expect(sizeCapped.height, equals(sizeOver.height));
    });

    test('width is always the fixed picker width plus chrome', () {
      for (final count in [0, 1, 3, 6, 10]) {
        final size = PickerLayout.windowSize(count);
        expect(size.width, equals(PickerLayout.width + 16));
      }
    });

    test('single browser height equals overhead + one row + chrome', () {
      final size = PickerLayout.windowSize(1);
      // height = _overhead + 1 * rowHeight + _chromeH
      expect(size.height, closeTo(100.0 + PickerLayout.rowHeight + 9.0, 0.001));
    });
  });
}
