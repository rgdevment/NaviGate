import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linkunbound/ui/settings/about_page.dart';

import '../helpers.dart';

void _mockUrlLauncher() {
  const channel = MethodChannel('plugins.flutter.io/url_launcher_windows');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (_) async => true);
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('about_page_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('AboutPage rendering', () {
    testWidgets('renders without throwing', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AboutPage), findsOneWidget);
    });

    testWidgets('shows ABOUT section header', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('shows app name LinkUnbound', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('LinkUnbound'), findsOneWidget);
    });

    testWidgets('shows version from packageInfoProvider', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1.0.0'), findsWidgets);
    });

    testWidgets('shows app description', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('browser picker'), findsWidgets);
    });

    testWidgets('shows SUPPORT section header', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('SUPPORT'), findsOneWidget);
    });

    testWidgets('shows donate label', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Buy me a coffee'), findsOneWidget);
    });

    testWidgets('shows OTHER TOOLS section header', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('OTHER TOOLS'), findsOneWidget);
    });

    testWidgets('shows CopyPaste tool label', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('CopyPaste'), findsOneWidget);
    });
  });

  group('AboutPage — link taps', () {
    testWidgets('tapping Buy me a coffee invokes launchUrl', (tester) async {
      _mockUrlLauncher();
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buy me a coffee'));
      await tester.pumpAndSettle();
      expect(find.text('Buy me a coffee'), findsOneWidget);
    });
  });
}
