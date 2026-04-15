final class PickerLayout {
  const PickerLayout._();

  static (int columns, int rows) grid(int browserCount) => switch (browserCount) {
        <= 0 => (0, 0),
        <= 4 => (browserCount, 1),
        <= 6 => (3, 2),
        <= 8 => (4, 2),
        _ => (3, (browserCount / 3).ceil()),
      };
}
