import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Frameless / borderless look (matches Windows runner).
    self.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.isMovableByWindowBackground = true
    self.standardWindowButton(.closeButton)?.isHidden = true
    self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    self.standardWindowButton(.zoomButton)?.isHidden = true

    // Initial size; matches the Settings window dimensions used on Windows.
    let initialSize = NSSize(width: 640, height: 700)
    let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
    let origin = NSPoint(
      x: screenFrame.midX - initialSize.width / 2,
      y: screenFrame.midY - initialSize.height / 2
    )
    self.setFrame(NSRect(origin: origin, size: initialSize), display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Wire native → Dart inbound events bridge.
    let inboundEvents = InboundEventsChannel(messenger: flutterViewController.engine.binaryMessenger)
    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
      appDelegate.attachInboundEvents(inboundEvents)
    }

    super.awakeFromNib()
  }
}
