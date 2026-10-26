import Foundation

nonisolated struct Endpoint<Response: Decodable & Sendable>: Sendable {
  let path: String
  let method: HttpMethod
  let queryItems: [URLQueryItem]
  let headers: [String: String]
  let body: Data?
  let responseKind: HttpResponseKind<Response>

  init(
    path: String,
    method: HttpMethod = .get,
    queryItems: [URLQueryItem] = [],
    headers: [String: String] = [:],
    body: Data? = nil,
    responseKind: HttpResponseKind<Response> = .json,
  ) {
    self.path = path
    self.method = method
    self.queryItems = queryItems
    self.headers = headers
    self.body = body
    self.responseKind = responseKind
  }
}

enum ApiRoute: String {
  case health
  case albums
  case tracks
}

extension Endpoint {
  nonisolated init(
    route: ApiRoute,
    method: HttpMethod = .get,
    queryItems: [URLQueryItem] = [],
    headers: [String: String] = [:],
    body: Data? = nil,
    responseKind: HttpResponseKind<Response> = .json,
  ) {
    self.path = route.rawValue
    self.method = method
    self.queryItems = queryItems
    self.headers = headers
    self.body = body
    self.responseKind = responseKind
  }
}
