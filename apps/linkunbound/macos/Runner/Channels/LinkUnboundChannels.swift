import FlutterMacOS

/// Single entry point that wires every native channel into the Flutter engine.
/// Call this from `MainFlutterWindow.awakeFromNib()` once the engine is alive.
final class LinkUnboundChannels {
  let inboundEvents: InboundEventsChannel
  let browserDetector: BrowserDetectorChannel
  let iconExtractor: IconExtractorChannel
  let registration: RegistrationChannel
  let startup: StartupChannel

  init(messenger: FlutterBinaryMessenger) {
    inboundEvents = InboundEventsChannel(messenger: messenger)
    browserDetector = BrowserDetectorChannel(messenger: messenger)
    iconExtractor = IconExtractorChannel(messenger: messenger)
    registration = RegistrationChannel(messenger: messenger)
    startup = StartupChannel(messenger: messenger)
  }
}
