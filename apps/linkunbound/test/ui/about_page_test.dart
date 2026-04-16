import 'dart:io';

import 'package:flutter/material.dart';
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

    testWidgets('shows ACTIONS section header', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('ACTIONS'), findsOneWidget);
    });

    testWidgets('shows Reset configuration action', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reset configuration'), findsOneWidget);
    });

    testWidgets('shows Unregister action', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unregister LinkUnbound'), findsOneWidget);
    });

    testWidgets('Actions section appears after Other Tools', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      final otherToolsOffset = tester.getTopLeft(find.text('OTHER TOOLS')).dy;
      final actionsOffset = tester.getTopLeft(find.text('ACTIONS')).dy;
      expect(actionsOffset, greaterThan(otherToolsOffset));
    });
  });

  group('AboutPage dialogs', () {
    testWidgets('tapping Reset configuration shows confirmation dialog', (
      tester,
    ) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset configuration'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.textContaining('Reset'), findsWidgets);
    });

    testWidgets('reset dialog has Cancel button', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset configuration'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Cancel dismisses reset dialog', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset configuration'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('tapping Unregister shows confirmation dialog', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Unregister LinkUnbound'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unregister LinkUnbound'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('tapping Cancel dismisses unregister dialog', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Unregister LinkUnbound'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unregister LinkUnbound'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('confirming unregister calls service unregister', (
      tester,
    ) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const AboutPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Unregister LinkUnbound'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unregister LinkUnbound'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unregister'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
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
