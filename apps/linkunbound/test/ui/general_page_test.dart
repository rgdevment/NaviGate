import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

import 'package:linkunbound/ui/settings/general_page.dart';

import '../helpers.dart';

const _chrome = Browser(
  id: 'chrome',
  name: 'Google Chrome',
  executablePath: 'chrome.exe',
  iconPath: 'chrome.png',
);

const _firefox = Browser(
  id: 'firefox',
  name: 'Firefox',
  executablePath: 'firefox.exe',
  iconPath: 'firefox.png',
);

const _edge = Browser(
  id: 'edge',
  name: 'Microsoft Edge',
  executablePath:
      r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
  iconPath: 'edge.png',
);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('general_page_test_');
  });

  tearDown(() async {
    for (var i = 0; i < 5; i++) {
      try {
        tempDir.deleteSync(recursive: true);
        break;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  });

  group('GeneralPage — browsers section', () {
    testWidgets('renders without throwing', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GeneralPage), findsOneWidget);
    });

    testWidgets('shows BROWSERS section header', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('BROWSERS'), findsOneWidget);
    });

    testWidgets('shows add browser tooltip', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Add custom browser'), findsOneWidget);
    });

    testWidgets('shows refresh browsers tooltip', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Refresh browsers'), findsOneWidget);
    });

    testWidgets('shows browser name in tile', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome, _firefox]);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Google Chrome'), findsOneWidget);
      expect(find.text('Firefox'), findsOneWidget);
    });

    testWidgets('shows popup menu for browser row', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome]);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('refresh with empty browsers shows no-changes snackbar', (
      tester,
    ) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Refresh browsers'));
      await tester.pumpAndSettle();
      expect(find.text('No changes detected'), findsOneWidget);
    });
  });

  group('GeneralPage — default browser section', () {
    testWidgets('shows DEFAULT BROWSER section header', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('DEFAULT BROWSER'), findsOneWidget);
    });

    testWidgets('shows not-default status when isDefault is false', (
      tester,
    ) async {
      final f = makeFixtures(dir: tempDir, isDefault: false);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('not the default browser'), findsOneWidget);
    });

    testWidgets('shows Set Default button when not default', (tester) async {
      final f = makeFixtures(dir: tempDir, isDefault: false);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Set default'), findsOneWidget);
    });

    testWidgets('shows is-default status when isDefault is true', (
      tester,
    ) async {
      final f = makeFixtures(dir: tempDir, isDefault: true);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('is set as the default'), findsOneWidget);
    });

    testWidgets('no Set Default button when is default', (tester) async {
      final f = makeFixtures(dir: tempDir, isDefault: true);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Set default'), findsNothing);
    });
  });

  group('GeneralPage — startup section', () {
    testWidgets('shows STARTUP section header', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('STARTUP'), findsOneWidget);
    });

    testWidgets('shows launch at startup label', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Launch at Windows startup'), findsOneWidget);
    });

    testWidgets('startup switch is off by default', (tester) async {
      final f = makeFixtures(dir: tempDir, isStartupEnabled: false);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isFalse);
    });

    testWidgets('startup switch shows on when isStartupEnabled is true', (
      tester,
    ) async {
      final f = makeFixtures(dir: tempDir, isStartupEnabled: true);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isTrue);
    });

    testWidgets('tapping startup switch calls service disable', (tester) async {
      final f = makeFixtures(dir: tempDir, isStartupEnabled: true);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsOneWidget);
    });
  });

  group('GeneralPage — language section', () {
    testWidgets('shows LANGUAGE section header', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('LANGUAGE'), findsWidgets);
    });

    testWidgets('shows Automatic option in dropdown', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Automatic (system)'), findsOneWidget);
    });

    testWidgets('opening dropdown shows all language options', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
    });

    testWidgets('selecting English updates locale', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(find.text('English'), findsOneWidget);
    });
  });

  group('GeneralPage — add/edit browser dialog', () {
    testWidgets('tapping add button shows dialog', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add custom browser'));
      await tester.pumpAndSettle();
      expect(find.text('Add custom browser'), findsWidgets);
    });

    testWidgets('add dialog shows Name field', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add custom browser'));
      await tester.pumpAndSettle();
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Executable path'), findsOneWidget);
    });

    testWidgets('add dialog Cancel closes dialog', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add custom browser'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('tapping edit on browser opens edit dialog', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome]);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Edit browser'), findsOneWidget);
    });

    testWidgets('edit dialog is pre-filled with browser name', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome]);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Google Chrome'), findsOneWidget);
    });

    testWidgets('add with empty fields does not add browser', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add custom browser'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
    });
  });

  group('GeneralPage — edge warning card', () {
    testWidgets('hides edge warning when no edge browser', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome, _firefox]);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Microsoft Edge detected'), findsNothing);
    });

    testWidgets(
      'shows edge warning card when edge browser present and not dismissed',
      (tester) async {
        final f = makeFixtures(dir: tempDir, browsers: [_edge]);
        await tester.pumpWidget(
          buildTestApp(const GeneralPage(), overrides: f.overrides),
        );
        await tester.pumpAndSettle();
        expect(find.text('Microsoft Edge detected'), findsOneWidget);
      },
    );

    testWidgets('hides edge warning when dismissed file already exists', (
      tester,
    ) async {
      File('${tempDir.path}/edge_warning_dismissed').writeAsStringSync('1');
      final f = makeFixtures(dir: tempDir, browsers: [_edge]);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text('Microsoft Edge detected'), findsNothing);
    });

    testWidgets('edge warning card shows body text', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_edge]);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Microsoft Teams'), findsOneWidget);
    });

    testWidgets('edge warning card shows dismiss button', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_edge]);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      expect(find.text("Got it, don't show again"), findsOneWidget);
    });

    testWidgets('tapping dismiss hides edge warning card', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_edge]);
      await tester.pumpWidget(
        buildTestApp(const GeneralPage(), overrides: f.overrides),
      );
      await tester.pumpAndSettle();
      final dismissButton = find.text("Got it, don't show again");
      await tester.ensureVisible(dismissButton);
      await tester.pumpAndSettle();
      await tester.tap(dismissButton);
      await tester.pumpAndSettle();
      expect(find.text('Microsoft Edge detected'), findsNothing);
    });
  });
}
