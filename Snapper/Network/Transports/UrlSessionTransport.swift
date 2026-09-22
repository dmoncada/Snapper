import Foundation

nonisolated final class UrlSessionTransport: HttpTransport, Sendable {
  private let session: URLSession

  init(
    memoryCacheCapacity: Int = 20 * 1_024 * 1_024,
    diskCacheCapacity: Int = 100 * 1_024 * 1_024,
    timeout: TimeInterval = 15
  ) {
    let cache = URLCache(
      memoryCapacity: memoryCacheCapacity,
      diskCapacity: diskCacheCapacity
    )
    let configuration = URLSessionConfiguration.default
    configuration.urlCache = cache
    configuration.requestCachePolicy = .useProtocolCachePolicy
    configuration.timeoutIntervalForRequest = timeout
    configuration.timeoutIntervalForResource = timeout * 2
    configuration.waitsForConnectivity = true

    session = URLSession(configuration: configuration)
  }

  func send(_ request: URLRequest) async throws -> HttpResponse {
    let (data, response) = try await session.data(for: request)

    guard let response = response as? HTTPURLResponse else {
      throw HttpTransportError.nonHttpResponse
    }

    return HttpResponse(data: data, response: response)
  }
}
