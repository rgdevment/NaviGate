import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linkunbound/ui/settings/maintenance_page.dart';

import '../helpers.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('maintenance_page_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('MaintenancePage rendering', () {
    testWidgets('renders without throwing', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const MaintenancePage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MaintenancePage), findsOneWidget);
    });

    testWidgets('shows MAINTENANCE section header', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const MaintenancePage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('MAINTENANCE'), findsOneWidget);
    });

    testWidgets('shows Export diagnostics action', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const MaintenancePage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Export diagnostics'), findsOneWidget);
    });

    testWidgets('shows Reset configuration action', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const MaintenancePage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reset configuration'), findsOneWidget);
    });

    testWidgets('shows Unregister action', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const MaintenancePage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unregister LinkUnbound'), findsOneWidget);
    });
  });

  group('MaintenancePage dialogs', () {
    testWidgets('tapping Reset configuration shows confirmation dialog', (
      tester,
    ) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const MaintenancePage(), overrides: f.overrides),
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
        buildTestApp(const MaintenancePage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset configuration'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Cancel dismisses reset dialog', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const MaintenancePage(), overrides: f.overrides),
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
        buildTestApp(const MaintenancePage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unregister LinkUnbound'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('tapping Cancel dismisses unregister dialog', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const MaintenancePage(), overrides: f.overrides),
      );
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
        buildTestApp(const MaintenancePage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unregister LinkUnbound'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unregister'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });
}
