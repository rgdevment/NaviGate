import 'dart:io';

import 'package:logging/logging.dart';
import 'package:navigate_core/navigate_core.dart';

final _log = Logger('WinIconExtractor');

final class WinIconExtractor implements IconExtractor {
  @override
  Future<String> extractIcon(String executablePath, String outputPath) async {
    final outFile = File(outputPath);
    if (outFile.existsSync()) return outputPath;

    await outFile.parent.create(recursive: true);

    final script = '''
Add-Type -AssemblyName System.Drawing
\$icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$executablePath")
if (\$icon) {
  \$bmp = \$icon.ToBitmap()
  \$bmp.Save("$outputPath", [System.Drawing.Imaging.ImageFormat]::Png)
  \$bmp.Dispose()
  \$icon.Dispose()
}
''';

    final result = await Process.run(
      'powershell',
      ['-NoProfile', '-NonInteractive', '-Command', script],
    );

    if (result.exitCode != 0 || !outFile.existsSync()) {
      _log.warning(
        'Icon extraction failed for $executablePath: ${result.stderr}',
      );
      throw IconExtractionException(executablePath, '${result.stderr}');
    }

    _log.fine('Extracted icon: $executablePath → $outputPath');
    return outputPath;
  }
}

final class IconExtractionException implements Exception {
  const IconExtractionException(this.executablePath, this.reason);
  final String executablePath;
  final String reason;

  @override
  String toString() =>
      'IconExtractionException: Failed to extract icon from '
      '$executablePath: $reason';
}
