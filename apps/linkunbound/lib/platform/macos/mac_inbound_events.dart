import 'dart:async';

import 'package:flutter/services.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

class MacInboundEvents implements InboundEventServer {
  MacInboundEvents() : _channel = const MethodChannel(_channelName);

  static const String _channelName = 'linkunbound/inbound_events';

  final MethodChannel _channel;
  // Broadcast so the bootstrap (and tests) can attach a listener after
  // `start()`. The `onListen` callback is what unblocks Swift: we only ask
  // it to flush pending events once we are actually subscribed, otherwise
  // events delivered between `start()` and the first `.listen()` would be
  // dropped — broadcast streams do not buffer.
  late final StreamController<InboundEvent> _controller =
      StreamController<InboundEvent>.broadcast(onListen: _signalReadyOnce);
  bool _started = false;
  bool _readySent = false;

  @override
  Stream<InboundEvent> get events => _controller.stream;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _channel.setMethodCallHandler(_onMethodCall);
    // Note: we do NOT call `ready` here. It is deferred until a Dart
    // listener attaches (see `_signalReadyOnce`) so cold-start URL events
    // queued by Swift in `preBootUrls`/`pending` are not flushed into a
    // listener-less broadcast stream and lost.
  }

  void _signalReadyOnce() {
    if (_readySent || !_started) return;
    _readySent = true;
    // Fire-and-forget: Swift does not return anything meaningful and we do
    // not want to block the listener attaching path on a platform round-trip.
    unawaited(_channel.invokeMethod<void>('ready'));
  }

  @override
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    _readySent = false;
    _channel.setMethodCallHandler(null);
    if (!_controller.isClosed) await _controller.close();
  }

  Future<void> _onMethodCall(MethodCall call) async {
    if (call.method != 'event') return;
    final args = (call.arguments as Map?)?.cast<String, dynamic>();
    if (args == null) return;
    try {
      _controller.add(InboundEvent.fromJson(args));
    } on FormatException {
      // ignore unknown actions for forward-compat
    }
  }
}
