import Foundation

enum ImageUrlSession {
  static let shared: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.urlCache = URLCache(
      memoryCapacity: 20 * 1024 * 1024,
      diskCapacity: 100 * 1024 * 1024
    )
    configuration.requestCachePolicy = .useProtocolCachePolicy

    return URLSession(configuration: configuration)
  }()
}

extension URLSession {
  static var images: URLSession { ImageUrlSession.shared }
}
