#if DEBUG
import Logging

enum PreviewLoggerFactory {
  static func makeLogger(_ feature: String) -> Logger {
    Logger(label: "Snapper.preview.\(feature)") { label in
      PreviewConsoleHandler(label: label)
    }
  }
}

struct PreviewConsoleHandler: LogHandler {
  let label: String
  var logLevel: Logger.Level = .info
  var metadata: Logger.Metadata = [:]

  subscript(metadataKey key: String) -> Logger.Metadata.Value? {
    get { metadata[key] }
    set { metadata[key] = newValue }
  }

  func log(event: LogEvent) {
    print("[\(event.level)] \(label): \(event.message)")
  }
}
#endif
