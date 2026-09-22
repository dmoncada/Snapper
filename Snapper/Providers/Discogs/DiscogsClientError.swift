import Foundation

nonisolated enum DiscogsClientError: LocalizedError, Sendable {
  case emptySearchTerm
  case invalidUrl
  case invalidToken
  case unexpectedStatusCode(Int)

  var errorDescription: String? {
    switch self {
    case .emptySearchTerm:
      "Enter a search term."
    case .invalidUrl:
      "Could not construct the Discogs request."
    case .invalidToken:
      "A valid Discogs token is required."
    case .unexpectedStatusCode(let statusCode):
      "Discogs returned HTTP status \(statusCode)."
    }
  }
}
