import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

import 'package:linkunbound/platform/macos/mac_inbound_events.dart';

const _channel = MethodChannel('linkunbound/inbound_events');
const _codec = StandardMethodCodec();

Future<void> _dispatchPlatformCall(String method, [dynamic arguments]) async {
  final ByteData data = _codec.encodeMethodCall(MethodCall(method, arguments));

  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(_channel.name, data, (_) {});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> outboundCalls;

  setUp(() {
    outboundCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          outboundCalls.add(call.method);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('start does not send ready until a listener subscribes', () async {
    final events = MacInboundEvents();
    addTearDown(events.stop);

    await events.start();
    // Give microtasks a chance to run; ready must NOT have been sent yet.
    await Future<void>.delayed(Duration.zero);
    expect(outboundCalls, isEmpty);

    final sub = events.events.listen((_) {});
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);
    expect(outboundCalls, ['ready']);
  });

  test('ready is sent only once across multiple listeners', () async {
    final events = MacInboundEvents();
    addTearDown(events.stop);

    await events.start();
    await events.start(); // start is idempotent

    final sub1 = events.events.listen((_) {});
    final sub2 = events.events.listen((_) {});
    addTearDown(sub1.cancel);
    addTearDown(sub2.cancel);
    await Future<void>.delayed(Duration.zero);

    expect(outboundCalls, ['ready']);
  });

  test('emits open_url event from native channel', () async {
    final events = MacInboundEvents();
    addTearDown(events.stop);
    await events.start();

    final future = expectLater(
      events.events,
      emits(
        isA<OpenUrlEvent>().having(
          (event) => event.url,
          'url',
          'https://example.com',
        ),
      ),
    );

    await _dispatchPlatformCall('event', {
      'action': 'open_url',
      'url': 'https://example.com',
    });

    await future;
  });

  test('emits show_settings event from native channel', () async {
    final events = MacInboundEvents();
    addTearDown(events.stop);
    await events.start();

    final future = expectLater(events.events, emits(isA<ShowSettingsEvent>()));

    await _dispatchPlatformCall('event', {'action': 'show_settings'});

    await future;
  });

  test('ignores unsupported payloads', () async {
    final events = MacInboundEvents();
    addTearDown(events.stop);
    await events.start();

    var emitted = false;
    final sub = events.events.listen((_) => emitted = true);
    addTearDown(sub.cancel);

    await _dispatchPlatformCall('event', {'action': 'unknown'});
    await _dispatchPlatformCall('noop', {'action': 'show_settings'});
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isFalse);
  });
}
