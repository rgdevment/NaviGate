import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linkunbound/platform/local_file_url.dart';

void main() {
  group('resolveLocalWebFile', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('lu_local_file_test_');
    });

    tearDown(() async {
      if (tmp.existsSync()) await tmp.delete(recursive: true);
    });

    test('returns absolute path for valid .html', () {
      final f = File('${tmp.path}/page.html')..writeAsStringSync('<html/>');
      final url = Uri.file(f.path).toString();
      // resolveSymbolicLinks may canonicalize /var → /private/var on macOS.
      expect(resolveLocalWebFile(url), endsWith('page.html'));
    });

    test('accepts .htm and .xhtml', () {
      final htm = File('${tmp.path}/a.htm')..writeAsStringSync('x');
      final xhtml = File('${tmp.path}/b.xhtml')..writeAsStringSync('x');
      expect(resolveLocalWebFile(Uri.file(htm.path).toString()), endsWith('a.htm'));
      expect(
        resolveLocalWebFile(Uri.file(xhtml.path).toString()),
        endsWith('b.xhtml'),
      );
    });

    test('rejects unsupported extension (.pdf)', () {
      final f = File('${tmp.path}/doc.pdf')..writeAsStringSync('x');
      expect(resolveLocalWebFile(Uri.file(f.path).toString()), isNull);
    });

    test('rejects no-extension files', () {
      final f = File('${tmp.path}/noext')..writeAsStringSync('x');
      expect(resolveLocalWebFile(Uri.file(f.path).toString()), isNull);
    });

    test('rejects non-existent file', () {
      final url = Uri.file('${tmp.path}/missing.html').toString();
      expect(resolveLocalWebFile(url), isNull);
    });

    test('rejects http(s) URLs', () {
      expect(resolveLocalWebFile('https://example.com/page.html'), isNull);
      expect(resolveLocalWebFile('http://example.com/page.htm'), isNull);
    });

    test('rejects unparseable input', () {
      expect(resolveLocalWebFile('not-a-url'), isNull);
    });
  });

  group('redactPath', () {
    test('keeps only parent + filename', () {
      expect(redactPath('/Users/me/projects/foo/bar.html'), '…/foo/bar.html');
    });

    test('handles short paths', () {
      expect(redactPath('/tmp/a.html'), '…/tmp/a.html');
      expect(redactPath('/a.html'), '…/a.html');
    });

    test('handles empty', () {
      expect(redactPath(''), '<empty>');
    });
  });
}
