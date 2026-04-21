import Cocoa
import FlutterMacOS

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
      case "activate":
        Self.activate()
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
    }
  }

  private static func applySettingsMode() {
    guard let win = mainWindow() else { return }
    DispatchQueue.main.async {
      win.styleMask.insert(.resizable)
      win.standardWindowButton(.closeButton)?.isHidden = true
      win.standardWindowButton(.miniaturizeButton)?.isHidden = true
      win.standardWindowButton(.zoomButton)?.isHidden = true
      win.level = .normal
    }
  }

  private static func activate() {
    guard let win = mainWindow() else { return }
    DispatchQueue.main.async {
      NSApp.activate(ignoringOtherApps: true)
      win.makeKeyAndOrderFront(nil)
    }
  }
}
