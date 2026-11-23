import Foundation

nonisolated enum AppDeepLink: String {
  case camera = "musicsnap://search/camera"

  var url: URL? { URL(string: rawValue) }

  init?(url: URL) {
    self.init(rawValue: url.absoluteString)
  }
}
