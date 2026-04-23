import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linkunbound/platform/windows/msix_startup_task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('linkunbound/startup_task');
  late List<MethodCall> log;

  setUp(() {
    log = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return _responses[call.method];
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('MsixStartupTaskState parsing', () {
    test('getState returns enabled', () async {
      _responses['getState'] = 'enabled';
      expect(await MsixStartupTask.getState(), MsixStartupTaskState.enabled);
    });

    test('getState returns disabled', () async {
      _responses['getState'] = 'disabled';
      expect(await MsixStartupTask.getState(), MsixStartupTaskState.disabled);
    });

    test('getState returns disabledByUser', () async {
      _responses['getState'] = 'disabledByUser';
      expect(
        await MsixStartupTask.getState(),
        MsixStartupTaskState.disabledByUser,
      );
    });

    test('getState returns disabledByPolicy', () async {
      _responses['getState'] = 'disabledByPolicy';
      expect(
        await MsixStartupTask.getState(),
        MsixStartupTaskState.disabledByPolicy,
      );
    });

    test('getState returns enabledByPolicy', () async {
      _responses['getState'] = 'enabledByPolicy';
      expect(
        await MsixStartupTask.getState(),
        MsixStartupTaskState.enabledByPolicy,
      );
    });

    test('getState returns unknown for unrecognized value', () async {
      _responses['getState'] = 'someFutureState';
      expect(await MsixStartupTask.getState(), MsixStartupTaskState.unknown);
    });

    test('getState returns unknown for null', () async {
      _responses['getState'] = null;
      expect(await MsixStartupTask.getState(), MsixStartupTaskState.unknown);
    });
  });

  group('MsixStartupTask.enable', () {
    test('calls enable method on channel', () async {
      _responses['enable'] = 'enabled';
      await MsixStartupTask.enable();
      expect(log.any((c) => c.method == 'enable'), isTrue);
    });

    test('returns state from channel response', () async {
      _responses['enable'] = 'disabledByUser';
      expect(
        await MsixStartupTask.enable(),
        MsixStartupTaskState.disabledByUser,
      );
    });

    test('returns enabled when channel returns enabled', () async {
      _responses['enable'] = 'enabled';
      expect(await MsixStartupTask.enable(), MsixStartupTaskState.enabled);
    });
  });

  group('MsixStartupTask.disable', () {
    test('calls disable method on channel', () async {
      _responses['disable'] = 'disabled';
      await MsixStartupTask.disable();
      expect(log.any((c) => c.method == 'disable'), isTrue);
    });

    test('returns state from channel response', () async {
      _responses['disable'] = 'disabled';
      expect(await MsixStartupTask.disable(), MsixStartupTaskState.disabled);
    });

    test('returns unknown when channel returns unrecognized value', () async {
      _responses['disable'] = null;
      expect(await MsixStartupTask.disable(), MsixStartupTaskState.unknown);
    });
  });
}

final _responses = <String, Object?>{};
