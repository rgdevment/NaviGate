import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';

final _log = Logger('WinInstance');
final _kernel32 = DynamicLibrary.open('kernel32.dll');

typedef _CreateMutexWNative = IntPtr Function(
  Pointer<Void> lpMutexAttributes,
  Int32 bInitialOwner,
  Pointer<Utf16> lpName,
);
typedef _CreateMutexWDart = int Function(
  Pointer<Void> lpMutexAttributes,
  int bInitialOwner,
  Pointer<Utf16> lpName,
);

typedef _WaitForSingleObjectNative = Uint32 Function(
  IntPtr hHandle,
  Uint32 dwMilliseconds,
);
typedef _WaitForSingleObjectDart = int Function(int hHandle, int dwMilliseconds);

typedef _ReleaseMutexNative = Int32 Function(IntPtr hMutex);
typedef _ReleaseMutexDart = int Function(int hMutex);

typedef _CloseHandleNative = Int32 Function(IntPtr hObject);
typedef _CloseHandleDart = int Function(int hObject);

typedef _AllowSetForegroundWindowNative = Int32 Function(Uint32 dwProcessId);
typedef _AllowSetForegroundWindowDart = int Function(int dwProcessId);

const _mutexName = r'Local\LinkUnbound_SingleInstance';
const _waitObject0 = 0;
const _waitAbandoned = 0x80;
const _asfwAny = 0xFFFFFFFF;

final class WinInstance {
  int _mutexHandle = 0;

  bool get isAcquired => _mutexHandle != 0;

  bool acquire() {
    if (_mutexHandle != 0) return false;

    final createMutex =
        _kernel32.lookupFunction<_CreateMutexWNative, _CreateMutexWDart>(
          'CreateMutexW',
        );
    final waitForSingleObject = _kernel32
        .lookupFunction<_WaitForSingleObjectNative, _WaitForSingleObjectDart>(
          'WaitForSingleObject',
        );

    final name = _mutexName.toNativeUtf16();
    try {
      final handle = createMutex(nullptr, 0, name);
      if (handle == 0) {
        _log.warning('CreateMutexW failed');
        return false;
      }

      final result = waitForSingleObject(handle, 0);
      if (result == _waitObject0 || result == _waitAbandoned) {
        _mutexHandle = handle;
        _log.info('Single instance acquired');
        return true;
      }

      final closeHandle =
          _kernel32.lookupFunction<_CloseHandleNative, _CloseHandleDart>(
            'CloseHandle',
          );
      closeHandle(handle);
      _log.info('Another instance already running');
      return false;
    } finally {
      calloc.free(name);
    }
  }

  void release() {
    if (_mutexHandle == 0) return;

    final releaseMutex =
        _kernel32.lookupFunction<_ReleaseMutexNative, _ReleaseMutexDart>(
          'ReleaseMutex',
        );
    final closeHandle =
        _kernel32.lookupFunction<_CloseHandleNative, _CloseHandleDart>(
          'CloseHandle',
        );

    releaseMutex(_mutexHandle);
    closeHandle(_mutexHandle);
    _mutexHandle = 0;
    _log.info('Single instance released');
  }

  static void allowForeground() {
    final user32 = DynamicLibrary.open('user32.dll');
    final allowSetForegroundWindow = user32.lookupFunction<
      _AllowSetForegroundWindowNative,
      _AllowSetForegroundWindowDart
    >('AllowSetForegroundWindow');
    allowSetForegroundWindow(_asfwAny);
  }

  static (double, double) getCursorPosition() {
    final user32 = DynamicLibrary.open('user32.dll');
    final getCursorPos = user32.lookupFunction<
      Int32 Function(Pointer<_POINT>),
      int Function(Pointer<_POINT>)
    >('GetCursorPos');
    final point = calloc<_POINT>();
    try {
      getCursorPos(point);
      return (point.ref.x.toDouble(), point.ref.y.toDouble());
    } finally {
      calloc.free(point);
    }
  }

  static (double, double) getScreenSize() {
    final user32 = DynamicLibrary.open('user32.dll');
    final getSystemMetrics = user32.lookupFunction<
      Int32 Function(Int32),
      int Function(int)
    >('GetSystemMetrics');
    return (getSystemMetrics(0).toDouble(), getSystemMetrics(1).toDouble());
  }
}

final class _POINT extends Struct {
  @Int32()
  external int x;

  @Int32()
  external int y;
}
