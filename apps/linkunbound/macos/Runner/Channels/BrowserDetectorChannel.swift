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

    // True browsers register themselves as the *primary* handler for the
    // http/https URL schemes — i.e. their `CFBundleURLTypes` entry that
    // contains "http"/"https" has either no `LSHandlerRank` (defaults to
    // "Default") or `LSHandlerRank = Owner`. Apps like iTerm, Hyper, Warp,
    // Office, etc. instead declare `LSHandlerRank = Alternate`, meaning
    // "I can open it if asked, but I'm not the canonical handler". This is
    // the structural signal we use to keep them out of the picker.
    let isHandlerRank: (URL) -> Bool = { appURL in
      guard
        let plistURL = Bundle(url: appURL)?.url(
          forResource: "Info",
          withExtension: "plist"
        ),
        let data = try? Data(contentsOf: plistURL),
        let plist = try? PropertyListSerialization.propertyList(
          from: data,
          options: [],
          format: nil
        ) as? [String: Any],
        let urlTypes = plist["CFBundleURLTypes"] as? [[String: Any]]
      else {
        // No URL types declared — be conservative and accept (Safari is
        // delivered without a parseable plist on some systems).
        return true
      }

      for entry in urlTypes {
        let schemes = (entry["CFBundleURLSchemes"] as? [String] ?? []).map {
          $0.lowercased()
        }
        guard schemes.contains("http") || schemes.contains("https") else {
          continue
        }
        let rank = (entry["LSHandlerRank"] as? String)?.lowercased() ?? "default"
        // "Default" / "Owner" => primary handler. "Alternate" / "None" => skip.
        return rank == "default" || rank == "owner"
      }
      // No http/https entry found in the Info.plist (the candidate appeared
      // because it declared the scheme dynamically). Treat as non-browser.
      return false
    }

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
            isHandlerRank(appURL),
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
