import 'dart:async';

import 'package:flutter/services.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

/// Receives inbound events forwarded from the macOS `AppDelegate`.
///
/// Native side (`InboundEventsChannel.swift`) calls `event` on the
/// `linkunbound/inbound_events` MethodChannel. We acknowledge readiness via
/// `ready` so events queued before Flutter was alive get flushed.
///
/// The internal controller is single-subscription so events emitted between
/// `start()` and `events.listen(...)` are buffered instead of dropped.
class MacInboundEvents implements InboundEventServer {
  MacInboundEvents() : _channel = const MethodChannel(_channelName);

  static const String _channelName = 'linkunbound/inbound_events';

  final MethodChannel _channel;
  final StreamController<InboundEvent> _controller =
      StreamController<InboundEvent>();
  bool _started = false;

  @override
  Stream<InboundEvent> get events => _controller.stream;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _channel.setMethodCallHandler(_onMethodCall);
    await _channel.invokeMethod<void>('ready');
  }

  @override
  Future<void> stop() async {
    _channel.setMethodCallHandler(null);
    await _controller.close();
  }

  Future<void> _onMethodCall(MethodCall call) async {
    if (call.method != 'event') return;
    final args = (call.arguments as Map?)?.cast<String, dynamic>();
    if (args == null) return;
    try {
      _controller.add(InboundEvent.fromJson(args));
    } on FormatException {
      // Unknown action; ignore (forward-compat).
    }
  }
}
