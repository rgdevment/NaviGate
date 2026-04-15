import '../models/browser.dart';

abstract interface class BrowserDetector {
  Future<List<Browser>> detect();
}
