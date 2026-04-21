import AppKit
import FlutterMacOS

/// `linkunbound/icon_extractor` — writes a PNG snapshot of an app's icon to disk.
final class IconExtractorChannel {
  static let channelName = "linkunbound/icon_extractor"

  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(FlutterMethodNotImplemented) }
      switch call.method {
      case "extract":
        let args = call.arguments as? [String: Any]
        guard let appPath = args?["appPath"] as? String,
              let outputPath = args?["outputPath"] as? String
        else {
          result(FlutterError(code: "bad_args", message: "appPath and outputPath required", details: nil))
          return
        }
        result(self.extract(appPath: appPath, outputPath: outputPath))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func extract(appPath: String, outputPath: String) -> String? {
    let icon = NSWorkspace.shared.icon(forFile: appPath)
    let target = NSSize(width: 64, height: 64)
    let resized = NSImage(size: target)
    resized.lockFocus()
    icon.draw(
      in: NSRect(origin: .zero, size: target),
      from: NSRect(origin: .zero, size: icon.size),
      operation: .copy,
      fraction: 1.0
    )
    resized.unlockFocus()

    guard let tiff = resized.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else { return nil }

    let url = URL(fileURLWithPath: outputPath)
    try? FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    do {
      try png.write(to: url, options: .atomic)
      return outputPath
    } catch {
      return nil
    }
  }
}
