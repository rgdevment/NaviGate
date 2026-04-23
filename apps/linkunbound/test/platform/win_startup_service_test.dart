import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linkunbound/platform/windows/msix_startup_task.dart';
import 'package:linkunbound/platform/windows/win_startup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── Pure helper function tests ───────────────────────────────────────────

  group('extractStartupExePath', () {
    test('extracts path from quoted value with args', () {
      const v = '"C:\\App\\myapp.exe" --background';
      expect(extractStartupExePath(v), 'C:\\App\\myapp.exe');
    });

    test('extracts path from quoted value without args', () {
      const v = '"C:\\App\\myapp.exe"';
      expect(extractStartupExePath(v), 'C:\\App\\myapp.exe');
    });

    test('extracts path from unquoted value with args', () {
      const v = r'C:\App\myapp.exe --background';
      expect(extractStartupExePath(v), r'C:\App\myapp.exe');
    });

    test('returns whole string when unquoted and no args', () {
      const v = r'C:\App\myapp.exe';
      expect(extractStartupExePath(v), v);
    });

    test('returns null for malformed quoted value (no closing quote)', () {
      const v = '"C:\\App\\myapp.exe';
      expect(extractStartupExePath(v), isNull);
    });

    test('handles leading/trailing whitespace', () {
      const v = '  "C:\\App\\app.exe" --background  ';
      expect(extractStartupExePath(v), 'C:\\App\\app.exe');
    });
  });

  group('isValidStartupExecutable', () {
    late Directory tempDir;
    late File validExe;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('win_startup_test_');
      validExe = File('${tempDir.path}\\real_app.exe')..createSync();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('returns true for existing .exe outside build dir', () {
      expect(isValidStartupExecutable(validExe.path), isTrue);
    });

    test('returns false when file does not exist', () {
      final missing = '${tempDir.path}\\ghost.exe';
      expect(isValidStartupExecutable(missing), isFalse);
    });

    test('returns false for non-.exe extension', () {
      final notExe = File('${tempDir.path}\\app.bat')..createSync();
      expect(isValidStartupExecutable(notExe.path), isFalse);
    });

    test('returns false for path containing build\\windows (backslash)', () {
      final devDir = Directory(
        '${tempDir.path}\\build\\windows\\runner\\Release',
      )..createSync(recursive: true);
      final devExe = File('${devDir.path}\\app.exe')..createSync();
      expect(isValidStartupExecutable(devExe.path), isFalse);
    });

    test('returns false for path containing build/windows (forward slash)', () {
      final devPath =
          '${tempDir.path.replaceAll(r'\', '/')}/build/windows/runner/app.exe';
      expect(isValidStartupExecutable(devPath), isFalse);
    });

    test('is case-insensitive for the build marker', () {
      final devDir = Directory(
        '${tempDir.path}\\Build\\Windows\\runner\\Release',
      )..createSync(recursive: true);
      final devExe = File('${devDir.path}\\app.exe')..createSync();
      expect(isValidStartupExecutable(devExe.path), isFalse);
    });

    test('is case-insensitive for the .exe extension', () {
      final upperExe = File('${tempDir.path}\\App.EXE')..createSync();
      expect(isValidStartupExecutable(upperExe.path), isTrue);
    });
  });

  // ─── Non-MSIX (standalone) registry paths ─────────────────────────────────

  group(
    'WinStartupService — standalone (non-MSIX)',
    skip: Platform.isWindows ? null : 'Registry API is Windows-only',
    () {
      late Directory tempDir;
      late File exeFile;

      WinStartupService standalone() =>
          WinStartupService(isMsixDetector: () => false);

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_standalone_');
        exeFile = File('${tempDir.path}\\app.exe')..createSync();
      });

      tearDown(() async {
        // Ensure the registry entry is always cleaned up after each test.
        await standalone().disable();
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      test('constructor does not throw', () {
        expect(standalone, returnsNormally);
      });

      test('isEnabled returns false when no Run entry exists', () async {
        await standalone().disable();
        expect(await standalone().isEnabled, isFalse);
      });

      test(
        'enable with non-exe path is a no-op (does not write registry)',
        () async {
          await standalone().enable('${tempDir.path}\\script.bat');
          expect(await standalone().isEnabled, isFalse);
        },
      );

      test('enable with dev build path is a no-op', () async {
        final devDir = Directory('${tempDir.path}\\build\\windows\\runner')
          ..createSync(recursive: true);
        final devExe = File('${devDir.path}\\app.exe')..createSync();
        await standalone().enable(devExe.path);
        expect(await standalone().isEnabled, isFalse);
      });

      test('enable with non-existent exe is a no-op', () async {
        await standalone().enable('${tempDir.path}\\missing.exe');
        expect(await standalone().isEnabled, isFalse);
      });

      test('disable when no Run entry does not throw', () async {
        await standalone().disable();
        expect(true, isTrue);
      });

      test('enable then isEnabled returns true', () async {
        await standalone().enable(exeFile.path);
        expect(await standalone().isEnabled, isTrue);
      });

      test('enable then disable → isEnabled returns false', () async {
        await standalone().enable(exeFile.path);
        await standalone().disable();
        expect(await standalone().isEnabled, isFalse);
      });

      test(
        'isEnabled auto-cleans stale entry pointing to missing exe',
        () async {
          await standalone().enable(exeFile.path);
          exeFile.deleteSync();
          expect(await standalone().isEnabled, isFalse);
          // After clean-up the entry is gone; second check must also be false.
          expect(await standalone().isEnabled, isFalse);
        },
      );
    },
  );

  // ─── MSIX paths (mocked channels) ─────────────────────────────────────────

  group('WinStartupService — MSIX', () {
    const startupChannel = MethodChannel('linkunbound/startup_task');
    const urlChannel = MethodChannel('plugins.flutter.io/url_launcher');
    final channelResponses = <String, Object?>{};
    late List<String> startupCalls;
    late List<String> urlCalls;

    WinStartupService msix() => WinStartupService(isMsixDetector: () => true);

    setUp(() {
      startupCalls = [];
      urlCalls = [];
      channelResponses.clear();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(startupChannel, (call) async {
            startupCalls.add(call.method);
            final resp = channelResponses[call.method];
            if (resp is Exception) throw resp;
            return resp;
          });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(urlChannel, (call) async {
            urlCalls.add(call.method);
            return true;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(startupChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(urlChannel, null);
    });

    test('constructor in MSIX context completes without throwing', () {
      expect(msix, returnsNormally);
    });

    test('enable calls startup channel enable', () async {
      channelResponses['enable'] = 'enabled';
      await msix().enable('whatever.exe');
      expect(startupCalls, contains('enable'));
    });

    test('enable with enabled state does not open Settings', () async {
      channelResponses['enable'] = 'enabled';
      await msix().enable('whatever.exe');
      expect(urlCalls, isEmpty);
    });

    test('enable with disabledByUser opens ms-settings:startupapps', () async {
      channelResponses['enable'] = 'disabledByUser';
      await msix().enable('whatever.exe');
      expect(urlCalls, isNotEmpty);
    });

    test('disable calls startup channel disable', () async {
      channelResponses['disable'] = 'disabled';
      await msix().disable();
      expect(startupCalls, contains('disable'));
    });

    test('isEnabled returns true when state is enabled', () async {
      channelResponses['getState'] = 'enabled';
      expect(await msix().isEnabled, isTrue);
    });

    test('isEnabled returns true when state is enabledByPolicy', () async {
      channelResponses['getState'] = 'enabledByPolicy';
      expect(await msix().isEnabled, isTrue);
    });

    test('isEnabled returns false when state is disabled', () async {
      channelResponses['getState'] = 'disabled';
      expect(await msix().isEnabled, isFalse);
    });

    test('isEnabled returns false when state is disabledByUser', () async {
      channelResponses['getState'] = 'disabledByUser';
      expect(await msix().isEnabled, isFalse);
    });

    test('isEnabled returns false when state is disabledByPolicy', () async {
      channelResponses['getState'] = 'disabledByPolicy';
      expect(await msix().isEnabled, isFalse);
    });

    test('isEnabled returns false when channel throws', () async {
      channelResponses['getState'] = Exception('WinRT unavailable');
      expect(await msix().isEnabled, isFalse);
    });
  });

  // ─── Channel mapping tests (MsixStartupTask directly) ─────────────────────

  group('MsixStartupTask — channel invocations and state mapping', () {
    const channel = MethodChannel('linkunbound/startup_task');
    final responses = <String, Object?>{};
    late List<String> calls;

    setUp(() {
      calls = [];
      responses.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return responses[call.method];
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('enable() invokes enable on the channel', () async {
      responses['enable'] = 'enabled';
      await MsixStartupTask.enable();
      expect(calls, contains('enable'));
    });

    test('disable() invokes disable on the channel', () async {
      responses['disable'] = 'disabled';
      await MsixStartupTask.disable();
      expect(calls, contains('disable'));
    });

    test('getState() invokes getState on the channel', () async {
      responses['getState'] = 'enabledByPolicy';
      await MsixStartupTask.getState();
      expect(calls, contains('getState'));
    });

    test('enable returns MsixStartupTaskState.enabled', () async {
      responses['enable'] = 'enabled';
      expect(await MsixStartupTask.enable(), MsixStartupTaskState.enabled);
    });

    test('disable returns MsixStartupTaskState.disabled', () async {
      responses['disable'] = 'disabled';
      expect(await MsixStartupTask.disable(), MsixStartupTaskState.disabled);
    });

    test('getState returns enabledByPolicy', () async {
      responses['getState'] = 'enabledByPolicy';
      expect(
        await MsixStartupTask.getState(),
        MsixStartupTaskState.enabledByPolicy,
      );
    });
  });
}
