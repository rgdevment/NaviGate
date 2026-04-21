import Cocoa
import FlutterMacOS

/// Bridge between native macOS URL/reopen callbacks and the Dart `bootstrap`.
///
/// Native side enqueues events as `[String: String]` (e.g. `{"action": "open_url", "url": "..."}`)
/// and forwards them on the `linkunbound/inbound_events` channel.
/// Dart calls `ready` once it has wired its handler so that any events queued
/// before the engine was alive are flushed.
final class InboundEventsChannel {
  static let channelName = "linkunbound/inbound_events"

  private let channel: FlutterMethodChannel
  private var pending: [[String: String]] = []
  private var dartReady = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(FlutterMethodNotImplemented) }
      switch call.method {
      case "ready":
        self.dartReady = true
        let queued = self.pending
        self.pending.removeAll()
        for event in queued {
          self.channel.invokeMethod("event", arguments: event)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func enqueueOpenUrl(_ url: String) {
    let event: [String: String] = ["action": "open_url", "url": url]
    forward(event)
  }

  func enqueueShowSettings() {
    let event: [String: String] = ["action": "show_settings"]
    forward(event)
  }

  private func forward(_ event: [String: String]) {
    if dartReady {
      DispatchQueue.main.async { [weak self] in
        self?.channel.invokeMethod("event", arguments: event)
      }
    } else {
      pending.append(event)
    }
  }
}
