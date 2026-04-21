import 'dart:convert';

sealed class InboundEvent {
  const InboundEvent();

  Map<String, dynamic> toJson();

  String encode() => jsonEncode(toJson());

  static InboundEvent decode(String raw) =>
      fromJson(jsonDecode(raw) as Map<String, dynamic>);

  static InboundEvent fromJson(Map<String, dynamic> json) =>
      switch (json['action'] as String?) {
        'open_url' => OpenUrlEvent(json['url'] as String),
        'show_settings' => const ShowSettingsEvent(),
        _ => throw FormatException(
          'Unknown inbound event action: ${json['action']}',
        ),
      };
}

final class OpenUrlEvent extends InboundEvent {
  const OpenUrlEvent(this.url);
  final String url;

  @override
  Map<String, dynamic> toJson() => {'action': 'open_url', 'url': url};
}

final class ShowSettingsEvent extends InboundEvent {
  const ShowSettingsEvent();

  @override
  Map<String, dynamic> toJson() => {'action': 'show_settings'};
}

abstract interface class InboundEventServer {
  Future<void> start();

  Stream<InboundEvent> get events;

  Future<void> stop();
}

abstract interface class InboundEventClient {
  Future<bool> send(InboundEvent event);
}
