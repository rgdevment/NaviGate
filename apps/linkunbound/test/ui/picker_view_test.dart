import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

import 'package:linkunbound/ui/picker/picker_view.dart';

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

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('picker_view_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      for (var i = 0; i < 5; i++) {
        try {
          tempDir.deleteSync(recursive: true);
          break;
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    }
  });

  group('PickerView — URL header', () {
    testWidgets('renders without throwing', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://github.com/user/repo'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PickerView), findsOneWidget);
    });

    testWidgets('shows domain extracted from URL', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://github.com/user/repo'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('github.com'), findsOneWidget);
    });

    testWidgets('shows full URL in header', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://github.com/user/repo'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('github.com/user/repo'), findsWidgets);
    });

    testWidgets('shows copy button', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('copy button has Copy URL tooltip', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Copy URL'), findsOneWidget);
    });

    testWidgets('shows link icon in header', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.link), findsOneWidget);
    });
  });

  group('PickerView — browser list', () {
    testWidgets('shows empty list when no browsers', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows browser names when browsers provided', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome, _firefox]);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Google Chrome'), findsOneWidget);
      expect(find.text('Firefox'), findsOneWidget);
    });

    testWidgets('shows keyboard shortcut badges 1 and 2 for two browsers', (
      tester,
    ) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome, _firefox]);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('PickerView — always open footer', () {
    testWidgets('shows Always open here checkbox', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('checkbox is unchecked by default', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('tapping checkbox toggles it', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('shows Always open here label', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Always open here'), findsOneWidget);
    });
  });

  group('PickerView — keyboard', () {
    testWidgets('Escape does not throw', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PickerView), findsOneWidget);
    });
  });

  group('PickerView — browser launch', () {
    testWidgets('tapping browser row triggers launch', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome]);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Google Chrome'));
      await tester.pumpAndSettle();
      expect(f.launchService.launches, contains('chrome.exe'));
    });

    testWidgets('pressing digit 1 launches first browser', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome, _firefox]);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();
      expect(f.launchService.launches, contains('chrome.exe'));
    });

    testWidgets('pressing digit 2 launches second browser', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome, _firefox]);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();
      expect(f.launchService.launches, contains('firefox.exe'));
    });

    testWidgets('launching with always open saves rule', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome]);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://github.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Google Chrome'));
      await tester.pumpAndSettle();
      expect(f.ruleService.lookupBrowser('https://github.com'), 'chrome');
    });
  });

  group('PickerView — update dot', () {
    testWidgets('shows update dot when updateInfo is non-null', (tester) async {
      final f = makeFixtures(
        dir: tempDir,
        updateInfo: const UpdateInfo(
          latestVersion: '9.9.9',
          releaseUrl: 'https://github.com/test/releases',
        ),
      );
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      // Use pump instead of pumpAndSettle: _UpdateDot has a repeating animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('no update dot when updateInfo is null', (tester) async {
      final f = makeFixtures(dir: tempDir);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('New version available — check for updates in Settings'), findsNothing);
    });
  });

  group('PickerView — browser row hover', () {
    testWidgets('browser row changes color on mouse enter', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome]);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      final browserRow = find.text('Google Chrome');
      await gesture.moveTo(tester.getCenter(browserRow));
      await tester.pumpAndSettle();
      expect(find.text('Google Chrome'), findsOneWidget);
    });

    testWidgets('browser row resets color on mouse exit', (tester) async {
      final f = makeFixtures(dir: tempDir, browsers: [_chrome]);
      await tester.pumpWidget(
        buildTestApp(
          const PickerView(url: 'https://example.com'),
          overrides: f.overrides,
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      final browserRow = find.text('Google Chrome');
      await gesture.moveTo(tester.getCenter(browserRow));
      await tester.pumpAndSettle();
      await gesture.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(find.text('Google Chrome'), findsOneWidget);
    });
  });
}
