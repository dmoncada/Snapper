import Foundation

extension URL {
  nonisolated static var baseUrl: Self {
    guard
      let value = Bundle.main.object(forInfoDictionaryKey: "SNAPPER_API_BASE_URL") as? String,
      let url = URL(string: value)
    else {
      fatalError("SNAPPER_API_BASE_URL not set.")
    }

    return url
  }
}
