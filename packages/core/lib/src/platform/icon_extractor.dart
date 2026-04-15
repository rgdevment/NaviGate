abstract interface class IconExtractor {
  Future<String> extractIcon(String executablePath, String outputPath);
}
