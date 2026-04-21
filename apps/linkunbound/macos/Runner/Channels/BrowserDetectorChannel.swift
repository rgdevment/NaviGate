import AppKit
import FlutterMacOS

/// `linkunbound/browser_detector` — discovers installed apps that handle web URLs.
final class BrowserDetectorChannel {
  static let channelName = "linkunbound/browser_detector"

  private let channel: FlutterMethodChannel
  private let ownBundleId: String

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    ownBundleId = Bundle.main.bundleIdentifier ?? "com.rgdevment.linkunbound"
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(FlutterMethodNotImplemented) }
      switch call.method {
      case "detect":
        result(self.detect())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func detect() -> [[String: String]] {
    let workspace = NSWorkspace.shared
    var seen = Set<String>()
    var browsers: [[String: String]] = []

    // Gather candidate bundle URLs that handle https. Almost every browser
    // also registers as an http handler, so a single query is enough.
    var candidateURLs: [URL] = []
    if let httpsURL = URL(string: "https://example.com") {
      candidateURLs.append(contentsOf: workspace.urlsForApplications(toOpen: httpsURL))
    }

    for appURL in candidateURLs {
      guard let bundle = Bundle(url: appURL),
            let bundleId = bundle.bundleIdentifier,
            bundleId != ownBundleId,
            !seen.contains(bundleId)
      else { continue }
      seen.insert(bundleId)

      let name = (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
        ?? (bundle.infoDictionary?["CFBundleName"] as? String)
        ?? appURL.deletingPathExtension().lastPathComponent
      let id = bundleId
        .lowercased()
        .replacingOccurrences(of: ".", with: "-")

      browsers.append([
        "id": id,
        "name": name,
        "executablePath": appURL.path,
      ])
    }

    return browsers
  }
}
