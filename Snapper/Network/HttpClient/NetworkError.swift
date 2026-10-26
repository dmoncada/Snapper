import Foundation

nonisolated enum NetworkError: LocalizedError, Sendable {
  case invalidUrl
  case invalidResponse
  case status(Int, message: String?)
  case decoding(String)
  case transport(URLError)
  case general(String)

  var errorDescription: String? {
    switch self {
    case .invalidUrl:
      "Could not construct the metadata request."
    case .invalidResponse, .decoding:
      "Could not read the metadata response."
    case .status(429, _):
      "Too many requests. Please try again shortly."
    case .status(502, _), .status(503, _):
      "Album metadata is temporarily unavailable. Please try again."
    case .status(let status, let message):
      if (400 ..< 500).contains(status), let message {
        message
      } else {
        "Album metadata request failed (HTTP \(status))."
      }
    case .transport(let error):
      error.localizedDescription
    case .general:
      "Album metadata request failed. Please try again."
    }
  }
}
