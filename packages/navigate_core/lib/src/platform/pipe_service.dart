import 'dart:convert';

sealed class PipeMessage {
  const PipeMessage();

  Map<String, dynamic> toJson();

  String encode() => jsonEncode(toJson());

  static PipeMessage decode(String raw) =>
      fromJson(jsonDecode(raw) as Map<String, dynamic>);

  static PipeMessage fromJson(Map<String, dynamic> json) =>
      switch (json['action'] as String?) {
        'open_url' => OpenUrlMessage(json['url'] as String),
        'show_settings' => const ShowSettingsMessage(),
        'ping' => const PingMessage(),
        _ => throw FormatException(
            'Unknown pipe message action: ${json['action']}'),
      };
}

final class OpenUrlMessage extends PipeMessage {
  const OpenUrlMessage(this.url);
  final String url;

  @override
  Map<String, dynamic> toJson() => {'action': 'open_url', 'url': url};
}

final class ShowSettingsMessage extends PipeMessage {
  const ShowSettingsMessage();

  @override
  Map<String, dynamic> toJson() => {'action': 'show_settings'};
}

final class PingMessage extends PipeMessage {
  const PingMessage();

  @override
  Map<String, dynamic> toJson() => {'action': 'ping'};
}

abstract interface class PipeServer {
  Future<void> start();

  Stream<PipeMessage> get messages;

  Future<void> stop();
}

abstract interface class PipeClient {
  Future<bool> send(PipeMessage message);
}
