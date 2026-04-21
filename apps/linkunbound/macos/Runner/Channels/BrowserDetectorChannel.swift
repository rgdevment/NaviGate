import AppKit
import FlutterMacOS
import UniformTypeIdentifiers

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

    // True browsers register themselves as VIEWERS for the `public.html`
    // UTI so the Finder can route .html files to them. Apps like iTerm,
    // Terminal, VS Code or Slack declare http/https URL-scheme handlers
    // (so `open https://…` works internally) but never claim to *display*
    // HTML — so they're absent from this set. This is a structural signal,
    // not a hand-maintained blacklist.
    let htmlViewers: Set<String> = {
      guard let html = UTType("public.html") else { return [] }
      let urls = workspace.urlsForApplications(toOpen: html)
      var ids: Set<String> = []
      for url in urls {
        if let id = Bundle(url: url)?.bundleIdentifier {
          ids.insert(id.lowercased())
        }
      }
      return ids
    }()

    // Only surface real, user-installed browsers from standard application
    // directories. This excludes Chrome-for-Testing, Playwright/Puppeteer
    // browsers cached under ~/.cache, Xcode device-support copies, etc.
    let allowedAppRoots: [String] = [
      "/Applications/",
      "/System/Applications/",
      "/System/Volumes/Preboot/",
      NSString("~/Applications/").expandingTildeInPath + "/",
    ]

    for appURL in candidateURLs {
      guard let bundle = Bundle(url: appURL),
            let bundleId = bundle.bundleIdentifier,
            bundleId != ownBundleId,
            htmlViewers.contains(bundleId.lowercased()),
            !seen.contains(bundleId)
      else { continue }

      let path = appURL.path
      guard allowedAppRoots.contains(where: { path.hasPrefix($0) }) else { continue }

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
