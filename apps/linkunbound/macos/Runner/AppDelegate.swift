import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  /// Set by `MainFlutterWindow` once the FlutterViewController is ready.
  var inboundEvents: InboundEventsChannel?

  /// URLs received before the channel exists are kept here and replayed after wiring.
  private var preBootUrls: [String] = []
  private var preBootShouldShowSettings = false

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // LinkUnbound stays alive in the menu bar (LSUIElement); closing the
    // settings window must not quit the app.
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    let strings = urls.map { $0.absoluteString }
    if let channel = inboundEvents {
      strings.forEach(channel.enqueueOpenUrl)
    } else {
      preBootUrls.append(contentsOf: strings)
    }
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if let channel = inboundEvents {
      channel.enqueueShowSettings()
    } else {
      preBootShouldShowSettings = true
    }
    return true
  }

  /// Called by `MainFlutterWindow` once the channel has been initialised.
  func attachInboundEvents(_ channel: InboundEventsChannel) {
    inboundEvents = channel
    preBootUrls.forEach(channel.enqueueOpenUrl)
    preBootUrls.removeAll()
    if preBootShouldShowSettings {
      channel.enqueueShowSettings()
      preBootShouldShowSettings = false
    }
  }
}
