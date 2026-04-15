import 'package:navigate_core/navigate_core.dart';

final class WinPipeServer implements PipeServer {
  @override
  Future<void> start() {
    throw UnimplementedError();
  }

  @override
  Stream<PipeMessage> get messages {
    throw UnimplementedError();
  }

  @override
  Future<void> stop() {
    throw UnimplementedError();
  }
}

final class WinPipeClient implements PipeClient {
  @override
  Future<bool> send(PipeMessage message) {
    throw UnimplementedError();
  }
}
