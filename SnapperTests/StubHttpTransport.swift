#if false
import Foundation

@testable import Snapper

nonisolated struct StubHttpTransport: HttpTransport {
  let statusCode: Int
  let body: String
  let inspect: @Sendable (URLRequest) -> Void

  func send(_ request: URLRequest) async throws -> HttpResponse {
    inspect(request)
    guard
      let url = request.url,
      let response = HTTPURLResponse(
        url: url,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil,
      )
    else {
      throw HttpTransportError.nonHttpResponse
    }
    return HttpResponse(data: Data(body.utf8), response: response)
  }
}
#endif
