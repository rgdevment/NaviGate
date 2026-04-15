import 'dart:io';

import 'package:logging/logging.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

final _log = Logger('WinIconExtractor');

final class WinIconExtractor implements IconExtractor {
  @override
  Future<String> extractIcon(String executablePath, String outputPath) async {
    final outFile = File(outputPath);
    if (outFile.existsSync()) return outputPath;

    await outFile.parent.create(recursive: true);

    final escapedExe = executablePath.replaceAll("'", "''");
    final escapedOut = outputPath.replaceAll("'", "''");

    final script = '''
Add-Type -AssemblyName System.Drawing
\$icon = [System.Drawing.Icon]::ExtractAssociatedIcon('$escapedExe')
if (\$icon) {
  \$bmp = \$icon.ToBitmap()
  \$bmp.Save('$escapedOut', [System.Drawing.Imaging.ImageFormat]::Png)
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
