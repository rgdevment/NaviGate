import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';
import 'package:linkunbound_core/linkunbound_core.dart';

final _log = Logger('WinPipeServer');

const _pipeName = r'\\.\pipe\LinkUnbound';
const _bufferSize = 4096;

const _pipeAccessDuplex = 0x00000003;
const _pipeTypeByte = 0x00000000;
const _pipeReadmodeByte = 0x00000000;
const _pipeWait = 0x00000000;
const _pipeUnlimitedInstances = 255;
const _openExisting = 3;
const _genericRead = 0x80000000;
const _genericWrite = 0x40000000;
const _invalidHandleValue = -1;

typedef _CreateNamedPipeWNative = IntPtr Function(
  Pointer<Utf16> lpName,
  Uint32 dwOpenMode,
  Uint32 dwPipeMode,
  Uint32 nMaxInstances,
  Uint32 nOutBufferSize,
  Uint32 nInBufferSize,
  Uint32 nDefaultTimeOut,
  Pointer<Void> lpSecurityAttributes,
);
typedef _CreateNamedPipeWDart = int Function(
  Pointer<Utf16> lpName,
  int dwOpenMode,
  int dwPipeMode,
  int nMaxInstances,
  int nOutBufferSize,
  int nInBufferSize,
  int nDefaultTimeOut,
  Pointer<Void> lpSecurityAttributes,
);

typedef _ConnectNamedPipeNative = Int32 Function(
  IntPtr hNamedPipe,
  Pointer<Void> lpOverlapped,
);
typedef _ConnectNamedPipeDart = int Function(
  int hNamedPipe,
  Pointer<Void> lpOverlapped,
);

typedef _DisconnectNamedPipeNative = Int32 Function(IntPtr hNamedPipe);
typedef _DisconnectNamedPipeDart = int Function(int hNamedPipe);

typedef _CreateFileWNative = IntPtr Function(
  Pointer<Utf16> lpFileName,
  Uint32 dwDesiredAccess,
  Uint32 dwShareMode,
  Pointer<Void> lpSecurityAttributes,
  Uint32 dwCreationDisposition,
  Uint32 dwFlagsAndAttributes,
  IntPtr hTemplateFile,
);
typedef _CreateFileWDart = int Function(
  Pointer<Utf16> lpFileName,
  int dwDesiredAccess,
  int dwShareMode,
  Pointer<Void> lpSecurityAttributes,
  int dwCreationDisposition,
  int dwFlagsAndAttributes,
  int hTemplateFile,
);

typedef _ReadFileNative = Int32 Function(
  IntPtr hFile,
  Pointer<Uint8> lpBuffer,
  Uint32 nNumberOfBytesToRead,
  Pointer<Uint32> lpNumberOfBytesRead,
  Pointer<Void> lpOverlapped,
);
typedef _ReadFileDart = int Function(
  int hFile,
  Pointer<Uint8> lpBuffer,
  int nNumberOfBytesToRead,
  Pointer<Uint32> lpNumberOfBytesRead,
  Pointer<Void> lpOverlapped,
);

typedef _WriteFileNative = Int32 Function(
  IntPtr hFile,
  Pointer<Uint8> lpBuffer,
  Uint32 nNumberOfBytesToWrite,
  Pointer<Uint32> lpNumberOfBytesWritten,
  Pointer<Void> lpOverlapped,
);
typedef _WriteFileDart = int Function(
  int hFile,
  Pointer<Uint8> lpBuffer,
  int nNumberOfBytesToWrite,
  Pointer<Uint32> lpNumberOfBytesWritten,
  Pointer<Void> lpOverlapped,
);

typedef _CloseHandleNative = Int32 Function(IntPtr hObject);
typedef _CloseHandleDart = int Function(int hObject);

typedef _CancelIoExNative = Int32 Function(
  IntPtr hFile,
  Pointer<Void> lpOverlapped,
);
typedef _CancelIoExDart = int Function(int hFile, Pointer<Void> lpOverlapped);

final class _NativePipe {
  _NativePipe._();

  static final _kernel32 = DynamicLibrary.open('kernel32.dll');

  static final createNamedPipe =
      _kernel32.lookupFunction<_CreateNamedPipeWNative, _CreateNamedPipeWDart>(
        'CreateNamedPipeW',
      );
  static final connectNamedPipe =
      _kernel32.lookupFunction<_ConnectNamedPipeNative, _ConnectNamedPipeDart>(
        'ConnectNamedPipe',
      );
  static final disconnectNamedPipe = _kernel32
      .lookupFunction<_DisconnectNamedPipeNative, _DisconnectNamedPipeDart>(
        'DisconnectNamedPipe',
      );
  static final createFile =
      _kernel32.lookupFunction<_CreateFileWNative, _CreateFileWDart>(
        'CreateFileW',
      );
  static final readFile =
      _kernel32.lookupFunction<_ReadFileNative, _ReadFileDart>('ReadFile');
  static final writeFile =
      _kernel32.lookupFunction<_WriteFileNative, _WriteFileDart>('WriteFile');
  static final closeHandle =
      _kernel32.lookupFunction<_CloseHandleNative, _CloseHandleDart>(
        'CloseHandle',
      );
  static final cancelIoEx =
      _kernel32.lookupFunction<_CancelIoExNative, _CancelIoExDart>(
        'CancelIoEx',
      );
}

final class WinPipeServer implements PipeServer {
  final _controller = StreamController<PipeMessage>.broadcast();
  Isolate? _isolate;
  ReceivePort? _receivePort;
  int _pipeHandle = 0;

  @override
  Stream<PipeMessage> get messages => _controller.stream;

  @override
  Future<void> start() async {
    if (_isolate != null) return;

    _receivePort = ReceivePort();
    _receivePort!.listen((data) {
      if (data is String) {
        try {
          final message = PipeMessage.decode(data);
          _controller.add(message);
        } on FormatException catch (e) {
          _log.warning('Invalid pipe message: $e');
        }
      } else if (data is int) {
        _pipeHandle = data;
      }
    });

    _isolate = await Isolate.spawn(
      _serverLoop,
      _receivePort!.sendPort,
    );
    _log.info('Pipe server started');
  }

  @override
  Future<void> stop() async {
    if (_pipeHandle != 0) {
      _NativePipe.cancelIoEx(_pipeHandle, nullptr);
      _NativePipe.disconnectNamedPipe(_pipeHandle);
      _NativePipe.closeHandle(_pipeHandle);
      _pipeHandle = 0;
    }

    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    await _controller.close();
    _log.info('Pipe server stopped');
  }

  static void _serverLoop(SendPort sendPort) {
    while (true) {
      final pipeName = _pipeName.toNativeUtf16();
      final handle = _NativePipe.createNamedPipe(
        pipeName,
        _pipeAccessDuplex,
        _pipeTypeByte | _pipeReadmodeByte | _pipeWait,
        _pipeUnlimitedInstances,
        _bufferSize,
        _bufferSize,
        0,
        nullptr,
      );
      calloc.free(pipeName);

      if (handle == _invalidHandleValue) continue;

      sendPort.send(handle);

      final connected = _NativePipe.connectNamedPipe(handle, nullptr);
      if (connected == 0) {
        final lastError = _getLastError();
        if (lastError != 535) {
          _NativePipe.closeHandle(handle);
          continue;
        }
      }

      final buffer = calloc<Uint8>(_bufferSize);
      final bytesRead = calloc<Uint32>();

      try {
        final success = _NativePipe.readFile(
          handle,
          buffer,
          _bufferSize - 1,
          bytesRead,
          nullptr,
        );

        if (success != 0 && bytesRead.value > 0) {
          final data = utf8.decode(
            buffer.asTypedList(bytesRead.value),
            allowMalformed: true,
          );
          sendPort.send(data);
        }
      } finally {
        calloc.free(buffer);
        calloc.free(bytesRead);
        _NativePipe.disconnectNamedPipe(handle);
        _NativePipe.closeHandle(handle);
      }
    }
  }

  static int _getLastError() {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    final getLastError =
        kernel32.lookupFunction<Uint32 Function(), int Function()>(
          'GetLastError',
        );
    return getLastError();
  }
}

final class WinPipeClient implements PipeClient {
  @override
  Future<bool> send(PipeMessage message) async {
    final pipeName = _pipeName.toNativeUtf16();
    final handle = _NativePipe.createFile(
      pipeName,
      _genericRead | _genericWrite,
      0,
      nullptr,
      _openExisting,
      0,
      0,
    );
    calloc.free(pipeName);

    if (handle == _invalidHandleValue) {
      _log.fine('Could not connect to pipe (no server running)');
      return false;
    }

    try {
      final data = utf8.encode(message.encode());
      final buffer = calloc<Uint8>(data.length);
      for (var i = 0; i < data.length; i++) {
        buffer[i] = data[i];
      }
      final bytesWritten = calloc<Uint32>();

      try {
        final success = _NativePipe.writeFile(
          handle,
          buffer,
          data.length,
          bytesWritten,
          nullptr,
        );
        return success != 0;
      } finally {
        calloc.free(buffer);
        calloc.free(bytesWritten);
      }
    } finally {
      _NativePipe.closeHandle(handle);
    }
  }
}
