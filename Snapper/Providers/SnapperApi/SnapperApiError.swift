import Foundation

nonisolated enum SnapperApiError: LocalizedError, Sendable {
  case invalidUrl
  case invalidResponse
  case httpStatus(Int)

  var errorDescription: String? {
    switch self {
    case .invalidUrl:
      "Could not construct the metadata request."
    case .invalidResponse:
      "Could not read the metadata response."
    case .httpStatus(429):
      "Too many requests. Please try again shortly."
    case .httpStatus(502), .httpStatus(503):
      "Album metadata is temporarily unavailable. Please try again."
    case .httpStatus(let status):
      "Album metadata request failed (HTTP \(status))."
    }
  }
}
