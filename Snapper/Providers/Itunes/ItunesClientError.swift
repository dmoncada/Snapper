import Foundation

nonisolated enum ItunesClientError: LocalizedError, Sendable {
  case invalidUrl
  case unexpectedStatusCode(Int)

  var errorDescription: String? {
    switch self {
    case .invalidUrl:
      "Unable to create the iTunes request."
    case .unexpectedStatusCode(let statusCode):
      "iTunes returned HTTP status \(statusCode)."
    }
  }
}
