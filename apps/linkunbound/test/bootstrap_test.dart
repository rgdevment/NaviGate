import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:linkunbound/bootstrap.dart';
import 'package:linkunbound/platform/cursor_locator.dart';
import 'package:linkunbound/platform/platform_bindings.dart';
import 'package:linkunbound/platform/tray_controller.dart';
import 'package:linkunbound/ui/picker/picker_window.dart';
import 'package:linkunbound/ui/settings/settings_window.dart';

const _windowChannel = MethodChannel('window_manager');
const _macWindowChannel = MethodChannel('linkunbound/window');

const _chrome = Browser(
  id: 'chrome',
  name: 'Google Chrome',
  executablePath:
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  iconPath: 'chrome.png',
);

final class _MethodChannelSpy {
  final List<MethodCall> calls = [];

  List<String> get methods => calls.map((call) => call.method).toList();

  void clear() => calls.clear();

  Future<dynamic> handle(MethodCall call) async {
    calls.add(call);
    switch (call.method) {
      case 'isFullScreen':
      case 'isMaximized':
      case 'isMinimized':
      case 'isVisible':
      case 'isFocused':
        return false;
      default:
        return null;
    }
  }
}

final class _FailingHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    throw const SocketException('blocked in tests');
  }
}

final class _FakeBrowserDetector implements BrowserDetector {
  _FakeBrowserDetector(this.detectedBrowsers);

  final List<Browser> detectedBrowsers;

  @override
  Future<List<Browser>> detect() async => detectedBrowsers;
}

final class _RecordingIconExtractor implements IconExtractor {
  final List<(String executablePath, String outputPath)> calls = [];

  @override
  Future<String> extractIcon(String executablePath, String outputPath) async {
    calls.add((executablePath, outputPath));
    return outputPath;
  }
}

final class _RecordingRegistrationService implements RegistrationService {
  final List<String> registerCalls = [];

  @override
  Future<Set<String>> get defaultAssociations async => {};

  @override
  Future<bool> get isDefault async => false;

  @override
  Future<void> register(String executablePath) async {
    registerCalls.add(executablePath);
  }

  @override
  Future<void> unregister() async {}
}

final class _FakeStartupService implements StartupService {
  @override
  Future<void> disable() async {}

  @override
  Future<void> enable(String executablePath) async {}

  @override
  Future<bool> get isEnabled async => false;
}

final class _RecordingLaunchService implements LaunchService {
  final List<({String executablePath, String url, List<String> extraArgs})>
  calls = [];

  @override
  Future<void> launch(
    String executablePath,
    String url,
    List<String> extraArgs,
  ) async {
    calls.add((
      executablePath: executablePath,
      url: url,
      extraArgs: List<String>.from(extraArgs),
    ));
  }
}

final class _FakeCursorLocator implements CursorLocator {
  _FakeCursorLocator();

  final (double, double) cursor = const (300.0, 200.0);
  final (double, double) screen = const (1280.0, 900.0);

  @override
  Future<(double, double)> cursorPosition() async => cursor;

  @override
  Future<(double, double)> screenSize() async => screen;
}

final class _FakeTrayController implements TrayController {
  int initCalls = 0;
  List<TrayMenuItem> menuItems = const [];
  VoidCallback? activationCallback;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> init({
    required String title,
    required String iconPath,
    required String tooltip,
  }) async {
    initCalls++;
  }

  @override
  void onActivated(VoidCallback callback) {
    activationCallback = callback;
  }

  @override
  Future<void> setMenu(List<TrayMenuItem> items) async {
    menuItems = items;
  }

  void activate() {
    activationCallback?.call();
  }
}

final class _FakeBindings implements PlatformBindings {
  _FakeBindings({
    required this.rootDir,
    List<Browser> detectedBrowsers = const [],
  }) : browserDetector = _FakeBrowserDetector(detectedBrowsers),
       iconExtractor = _RecordingIconExtractor(),
       registrationService = _RecordingRegistrationService(),
       startupService = _FakeStartupService(),
       launchService = _RecordingLaunchService(),
       trayController = _FakeTrayController(),
       cursorLocator = _FakeCursorLocator(),
       _events = StreamController<InboundEvent>.broadcast() {
    appDataDir.createSync(recursive: true);
    iconsDir.createSync(recursive: true);
    trayIconPathFile.writeAsStringSync('icon');
  }

  final Directory rootDir;
  final InboundEvent? initial = null;
  final StreamController<InboundEvent> _events;

  @override
  final BrowserDetector browserDetector;

  @override
  final _RecordingIconExtractor iconExtractor;

  @override
  final _RecordingLaunchService launchService;

  @override
  final _RecordingRegistrationService registrationService;

  @override
  final _FakeStartupService startupService;

  @override
  final _FakeTrayController trayController;

  @override
  final CursorLocator cursorLocator;

  int claimCalls = 0;
  int releaseCalls = 0;
  int tryDelegateCalls = 0;

  @override
  Directory get appDataDir => Directory('${rootDir.path}/app-data');

  @override
  File get browsersFile => File('${appDataDir.path}/browsers.json');

  @override
  File get edgeWarningFile => File('${appDataDir.path}/edge_warning_dismissed');

  @override
  String get executablePath =>
      '/Applications/LinkUnbound.app/Contents/MacOS/LinkUnbound';

  @override
  Directory get iconsDir => Directory('${appDataDir.path}/icons');

  @override
  InboundEvent? get initialEvent => initial;

  @override
  Stream<InboundEvent> get inboundEvents => _events.stream;

  @override
  File get localeFile => File('${appDataDir.path}/locale');

  @override
  File get logFile => File('${appDataDir.path}/linkunbound.log');

  @override
  File get rulesFile => File('${appDataDir.path}/rules.json');

  File get trayIconPathFile => File('${appDataDir.path}/tray.png');

  @override
  String get trayIconPath => trayIconPathFile.path;

  @override
  Future<bool> claim() async {
    claimCalls++;
    return true;
  }

  Future<void> close() async {
    await _events.close();
  }

  Future<void> emit(InboundEvent event) async {
    _events.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> release() async {
    releaseCalls++;
  }

  Future<void> seed({
    List<Browser> browsers = const [],
    List<Rule> rules = const [],
  }) async {
    final browserService = BrowserService(
      configFile: browsersFile,
      browserDetector: browserDetector,
    );
    for (final browser in browsers) {
      browserService.addBrowser(browser);
    }
    await browserService.save();

    final ruleService = RuleService(rulesFile: rulesFile);
    for (final rule in rules) {
      ruleService.addRule(rule);
    }
    await ruleService.save();
  }

  @override
  Future<bool> tryDelegate(InboundEvent? event) async {
    tryDelegateCalls++;
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late _MethodChannelSpy windowSpy;
  late _MethodChannelSpy macWindowSpy;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('bootstrap_test_');
    PackageInfo.setMockInitialValues(
      appName: 'LinkUnbound',
      packageName: 'dev.rg.LinkUnbound',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'sig',
    );
    windowSpy = _MethodChannelSpy();
    macWindowSpy = _MethodChannelSpy();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_windowChannel, windowSpy.handle);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_macWindowChannel, macWindowSpy.handle);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_windowChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_macWindowChannel, null);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> _boot(
    WidgetTester tester,
    _FakeBindings bindings,
    List<String> args,
  ) async {
    await HttpOverrides.runZoned(
      () => bootstrap(bindings, args),
      createHttpClient: (_) => _FailingHttpClient(),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('first boot scans browsers, extracts icons, and opens settings', (
    tester,
  ) async {
    final bindings = _FakeBindings(
      rootDir: tempDir,
      detectedBrowsers: const [_chrome],
    );
    addTearDown(bindings.close);

    await _boot(tester, bindings, const []);

    expect(bindings.claimCalls, 1);
    expect(bindings.tryDelegateCalls, 1);
    expect(bindings.registrationService.registerCalls, [
      bindings.executablePath,
    ]);
    expect(bindings.iconExtractor.calls, hasLength(1));
    expect(bindings.iconExtractor.calls.single.$1, _chrome.executablePath);
    expect(bindings.trayController.initCalls, 1);
    expect(
      bindings.trayController.menuItems
          .map((item) => item.label)
          .whereType<String>(),
      containsAll(['Settings', 'Exit']),
    );
    expect(find.byType(SettingsWindow), findsOneWidget);
  });

  testWidgets('background launch stays hidden until tray activation', (
    tester,
  ) async {
    final bindings = _FakeBindings(rootDir: tempDir);
    addTearDown(bindings.close);

    await _boot(tester, bindings, const ['--background']);

    expect(find.byType(SettingsWindow), findsNothing);

    bindings.trayController.activate();
    await tester.pump();
    await tester.pump();

    expect(find.byType(SettingsWindow), findsOneWidget);
    expect(macWindowSpy.methods, contains('setSettingsMode'));
    expect(macWindowSpy.methods, contains('activate'));
  });

  testWidgets('matching rule launches browser instead of opening picker', (
    tester,
  ) async {
    final bindings = _FakeBindings(rootDir: tempDir);
    addTearDown(bindings.close);
    await bindings.seed(
      browsers: const [_chrome],
      rules: const [Rule(domain: 'example.com', browserId: 'chrome')],
    );

    await _boot(tester, bindings, const ['--background']);
    await bindings.emit(const OpenUrlEvent('https://example.com/docs'));
    await tester.pump();
    await tester.pump();

    expect(bindings.launchService.calls, hasLength(1));
    expect(
      bindings.launchService.calls.single.executablePath,
      _chrome.executablePath,
    );
    expect(bindings.launchService.calls.single.url, 'https://example.com/docs');
    expect(find.byType(PickerWindow), findsNothing);
  });

  testWidgets('safe links are unwrapped before rule-based launch', (
    tester,
  ) async {
    final bindings = _FakeBindings(rootDir: tempDir);
    addTearDown(bindings.close);
    await bindings.seed(
      browsers: const [_chrome],
      rules: const [Rule(domain: 'example.com', browserId: 'chrome')],
    );

    await _boot(tester, bindings, const ['--background']);
    await bindings.emit(
      OpenUrlEvent(
        'https://nam12.safelinks.protection.outlook.com/?url=${Uri.encodeComponent('https://example.com/report?id=7')}',
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(bindings.launchService.calls, hasLength(1));
    expect(
      bindings.launchService.calls.single.url,
      'https://example.com/report?id=7',
    );
  });

  testWidgets('valid local html file opens the picker', (tester) async {
    final bindings = _FakeBindings(
      rootDir: tempDir,
      detectedBrowsers: const [_chrome],
    );
    addTearDown(bindings.close);
    final htmlFile = File('${tempDir.path}/preview.html')
      ..writeAsStringSync('<html></html>');

    await _boot(tester, bindings, const ['--background']);
    await bindings.emit(OpenUrlEvent(htmlFile.uri.toString()));
    await tester.pump();
    await tester.pump();

    expect(find.byType(PickerWindow), findsOneWidget);
    expect(macWindowSpy.methods, contains('setPickerMode'));
  });

  testWidgets('unsupported local file is ignored', (tester) async {
    final bindings = _FakeBindings(rootDir: tempDir);
    addTearDown(bindings.close);
    final txtFile = File('${tempDir.path}/notes.txt')..writeAsStringSync('hi');

    await _boot(tester, bindings, const ['--background']);
    await bindings.emit(OpenUrlEvent(txtFile.uri.toString()));
    await tester.pump();
    await tester.pump();

    expect(bindings.launchService.calls, isEmpty);
    expect(find.byType(PickerWindow), findsNothing);
  });
}
