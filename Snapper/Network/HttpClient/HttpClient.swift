import Foundation

nonisolated struct HttpClient: Sendable {
  let baseUrl: URL
  let transport: any HttpTransport

  init(baseUrl: URL, transport: any HttpTransport) {
    self.baseUrl = baseUrl
    self.transport = transport
  }

  @concurrent
  func send<Response: Decodable & Sendable>(
    _ endpoint: Endpoint<Response>
  ) async throws -> Response {
    let request = try makeRequest(for: endpoint)
    let result: HttpResponse

    do {
      try Task.checkCancellation()
      result = try await transport.send(request)
    } catch is CancellationError {
      throw CancellationError()
    } catch let error as URLError where error.code == .cancelled {
      throw CancellationError()
    } catch let error as URLError {
      throw NetworkError.transport(error)
    } catch is HttpTransportError {
      throw NetworkError.invalidResponse
    } catch {
      throw NetworkError.general(String(describing: error))
    }

    let status = result.response.statusCode

    guard (200 ..< 300).contains(status) else {
      throw NetworkError.status(status, message: serverMessage(in: result.data))
    }

    try Task.checkCancellation()

    switch endpoint.responseKind {
    case .empty(let value):
      return value

    case .json:
      do {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let value = try decoder.decode(Response.self, from: result.data)
        try Task.checkCancellation()

        return value
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        throw NetworkError.decoding(String(describing: error))
      }
    }
  }

  private func makeRequest<Response>(
    for endpoint: Endpoint<Response>
  ) throws(NetworkError) -> URLRequest {
    guard
      var components = URLComponents(
        url: baseUrl.appending(path: endpoint.path),
        resolvingAgainstBaseURL: false,
      )
    else {
      throw .invalidUrl
    }

    let items = endpoint.queryItems.filter { $0.value != nil }

    if items.count > 0 {
      components.queryItems = (components.queryItems ?? []) + items
    }

    guard let url = components.url else {
      throw .invalidUrl
    }

    var request = URLRequest(url: url)

    request.httpMethod = endpoint.method.rawValue
    request.httpBody = endpoint.body

    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    for (name, value) in endpoint.headers {
      request.setValue(value, forHTTPHeaderField: name)
    }

    return request
  }

  private func serverMessage(in data: Data) -> String? {
    guard
      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let message = object["detail"] as? String ?? object["message"] as? String,
      message.count > 0
    else {
      return nil
    }

    return message
  }
}
