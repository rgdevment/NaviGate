import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    self.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.isMovableByWindowBackground = true

    let initialSize = NSSize(width: 640, height: 700)
    let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
    let origin = NSPoint(
      x: screenFrame.midX - initialSize.width / 2,
      y: screenFrame.midY - initialSize.height / 2
    )
    self.setFrame(NSRect(origin: origin, size: initialSize), display: false)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channels = LinkUnboundChannels(messenger: flutterViewController.engine.binaryMessenger)
    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
      appDelegate.attachChannels(channels)
    }

    super.awakeFromNib()

    self.orderOut(nil)
  }
}
