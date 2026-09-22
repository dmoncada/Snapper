import Foundation

nonisolated struct HttpResponse: Sendable {
  let data: Data
  let response: HTTPURLResponse
}

nonisolated enum HttpTransportError: Error, Sendable {
  case nonHttpResponse
}

nonisolated protocol HttpTransport: Sendable {
  func send(_ request: URLRequest) async throws -> HttpResponse
}
