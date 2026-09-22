import Foundation

nonisolated struct ItunesStorefront: Sendable, Hashable {
  let countryCode: String

  init(countryCode: String = "us") {
    self.countryCode = countryCode.lowercased()
  }
}
