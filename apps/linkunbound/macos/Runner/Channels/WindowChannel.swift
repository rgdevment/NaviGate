import Cocoa
import FlutterMacOS

/// `linkunbound/window` — runtime-controlled NSWindow tweaks the Flutter side
/// triggers as the app switches between picker and settings modes.
final class WindowChannel {
  static let channelName = "linkunbound/window"

  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard self != nil else { return result(FlutterMethodNotImplemented) }
      switch call.method {
      case "setPickerMode":
        Self.applyPickerMode()
        result(nil)
      case "setSettingsMode":
        Self.applySettingsMode()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func mainWindow() -> NSWindow? {
    NSApplication.shared.windows.first
  }

  private static func applyPickerMode() {
    guard let win = mainWindow() else { return }
    DispatchQueue.main.async {
      win.styleMask.remove(.resizable)
      win.standardWindowButton(.closeButton)?.isHidden = true
      win.standardWindowButton(.miniaturizeButton)?.isHidden = true
      win.standardWindowButton(.zoomButton)?.isHidden = true
      win.level = .statusBar
      // LSUIElement apps don't auto-activate on window show — without these
      // calls the picker appears already "blurred" and would dismiss itself
      // immediately via `onWindowBlur`.
      NSApp.activate(ignoringOtherApps: true)
      win.makeKeyAndOrderFront(nil)
    }
  }

  private static func applySettingsMode() {
    guard let win = mainWindow() else { return }
    DispatchQueue.main.async {
      win.styleMask.insert(.resizable)
      // Hide the traffic-light buttons in Settings too — the in-app "Salir"
      // button is the canonical way to close the window on macOS for this
      // LSUIElement app, matching the Windows-style chrome.
      win.standardWindowButton(.closeButton)?.isHidden = true
      win.standardWindowButton(.miniaturizeButton)?.isHidden = true
      win.standardWindowButton(.zoomButton)?.isHidden = true
      win.level = .normal
      NSApp.activate(ignoringOtherApps: true)
      win.makeKeyAndOrderFront(nil)
    }
  }
}
