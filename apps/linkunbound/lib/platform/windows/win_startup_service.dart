import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:win32_registry/win32_registry.dart';

import 'msix_startup_task.dart';
import 'win_package_context.dart';

final _log = Logger('WinStartupService');

const _runKeyPath = r'Software\Microsoft\Windows\CurrentVersion\Run';
const _valueName = 'LinkUnbound';
const _devBuildMarker = r'\build\windows\';

final class WinStartupService implements StartupService {
  WinStartupService({@visibleForTesting bool Function()? isMsixDetector})
    : _isMsix = isMsixDetector ?? isRunningInMsix {
    if (_isMsix()) {
      _cleanLegacyRunEntry();
    }
  }

  final bool Function() _isMsix;

  @override
  Future<void> enable(String executablePath) async {
    if (_isMsix()) {
      final state = await MsixStartupTask.enable();
      _log.fine('MSIX startup state after enable: $state');
      if (state == MsixStartupTaskState.disabledByUser) {
        _log.info('Startup disabled by user; opening Windows Settings');
        await launchUrl(Uri.parse('ms-settings:startupapps'));
      }
      return;
    }

    if (!_isValidExecutable(executablePath)) {
      _deleteRunEntry();
      return;
    }

    final key = Registry.openPath(
      RegistryHive.currentUser,
      path: _runKeyPath,
      desiredAccessRights: AccessRights.allAccess,
    );
    key.createValue(
      RegistryValue(
        _valueName,
        RegistryValueType.string,
        '"${executablePath.replaceAll('/', '\\')}" --background',
      ),
    );
    key.close();
  }

  @override
  Future<void> disable() async {
    if (_isMsix()) {
      final state = await MsixStartupTask.disable();
      _log.fine('MSIX startup state after disable: $state');
      return;
    }
    _deleteRunEntry();
  }

  @override
  Future<bool> get isEnabled async {
    if (_isMsix()) {
      try {
        final state = await MsixStartupTask.getState();
        return state == MsixStartupTaskState.enabled ||
            state == MsixStartupTaskState.enabledByPolicy;
      } on Object catch (e) {
        _log.warning('MSIX getState failed: $e');
        return false;
      }
    }
    try {
      final key = Registry.openPath(
        RegistryHive.currentUser,
        path: _runKeyPath,
      );
      final value = key.getValueAsString(_valueName);
      key.close();
      if (value == null || value.isEmpty) return false;
      final exePath = _extractExePath(value);
      if (exePath != null && !_isValidExecutable(exePath)) {
        _deleteRunEntry();
        return false;
      }
      return true;
    } on Exception {
      return false;
    }
  }

  bool _isValidExecutable(String path) => isValidStartupExecutable(path);

  String? _extractExePath(String runValue) => extractStartupExePath(runValue);

  void _deleteRunEntry() {
    try {
      final key = Registry.openPath(
        RegistryHive.currentUser,
        path: _runKeyPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      try {
        key.deleteValue(_valueName);
      } on Exception {
        // value already absent
      }
      key.close();
    } on Exception {
      // run key not present
    }
  }

  void _cleanLegacyRunEntry() {
    try {
      _deleteRunEntry();
      _log.fine('Legacy HKCU\\Run\\$_valueName cleaned (MSIX context)');
    } on Object catch (e) {
      _log.fine('Legacy Run cleanup skipped: $e');
    }
  }
}

@visibleForTesting
bool isValidStartupExecutable(String path) {
  final normalized = path.replaceAll('/', r'\').toLowerCase();
  if (!normalized.endsWith('.exe')) return false;
  if (normalized.contains(_devBuildMarker)) return false;
  if (!File(path).existsSync()) return false;
  return true;
}

@visibleForTesting
String? extractStartupExePath(String runValue) {
  final trimmed = runValue.trim();
  if (trimmed.startsWith('"')) {
    final end = trimmed.indexOf('"', 1);
    if (end > 1) return trimmed.substring(1, end);
    return null;
  }
  final spaceIdx = trimmed.indexOf(' ');
  return spaceIdx > 0 ? trimmed.substring(0, spaceIdx) : trimmed;
}
