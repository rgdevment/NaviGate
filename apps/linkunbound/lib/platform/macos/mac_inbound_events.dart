import 'dart:async';

import 'package:flutter/services.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

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
