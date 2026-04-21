import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Frameless / borderless look (matches Windows runner). On macOS we KEEP
    // the standard traffic-light buttons because they are the platform idiom;
    // the Dart `TitleBar` widget hides its custom Windows-style close button
    // when running on macOS so the two don't overlap.
    self.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.isMovableByWindowBackground = true

    // Initial size; matches the Settings window dimensions used on Windows.
    let initialSize = NSSize(width: 640, height: 700)
    let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
    let origin = NSPoint(
      x: screenFrame.midX - initialSize.width / 2,
      y: screenFrame.midY - initialSize.height / 2
    )
    self.setFrame(NSRect(origin: origin, size: initialSize), display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Wire native channels and hand them to the AppDelegate so they outlive
    // this scope (otherwise the channel handlers would fire on a deallocated
    // `self`, returning FlutterMethodNotImplemented).
    let channels = LinkUnboundChannels(messenger: flutterViewController.engine.binaryMessenger)
    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
      appDelegate.attachChannels(channels)
    }

    super.awakeFromNib()
  }
}
