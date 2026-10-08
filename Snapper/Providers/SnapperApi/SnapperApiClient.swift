import Foundation

nonisolated struct SnapperApiClient: Sendable {
  private let baseUrlString: String
  private let transport: any HttpTransport

  init(
    baseUrlString: String? = nil,
    transport: any HttpTransport = UrlSessionTransport(timeout: 45),
  ) {
    self.baseUrlString =
      baseUrlString
      ?? (Bundle.main.object(forInfoDictionaryKey: "SNAPPER_API_BASE_URL") as? String ?? "")
    self.transport = transport
  }

  func searchAlbums(matching query: String) async throws -> [AlbumCandidate] {
    let url = try makeUrl(
      path: "v1/albums/search",
      queryItems: [URLQueryItem(name: "q", value: query)],
    )
    return try await send(URLRequest(url: url))
  }

  func searchAlbums(withBarcode barcode: String) async throws -> [AlbumCandidate] {
    let url = try makeUrl(path: "v1/albums/by-barcode/\(barcode)")
    return try await send(URLRequest(url: url))
  }

  func resolveTracklist(_ body: AlbumTracklistRequest) async throws -> AlbumTracklist {
    let url = try makeUrl(path: "v1/tracklists/resolve")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = try JSONEncoder().encode(body)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let response: ApiTracklistResponse = try await send(request)
    let source: AlbumTracklistSource
    switch response.source {
    case "itunes":
      source = .itunes(response.itunesUrl)
    case "discogs":
      source = .discogs
    default:
      throw SnapperApiError.invalidResponse
    }
    return AlbumTracklist(tracks: response.tracks, source: source)
  }

  private func makeUrl(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
    guard
      let baseUrl = URL(string: baseUrlString),
      var components = URLComponents(
        url: baseUrl.appending(path: path),
        resolvingAgainstBaseURL: false,
      )
    else {
      throw SnapperApiError.invalidUrl
    }
    components.queryItems = queryItems.isEmpty ? nil : queryItems
    guard let url = components.url else {
      throw SnapperApiError.invalidUrl
    }
    return url
  }

  private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
    let response = try await transport.send(request)
    guard (200 ..< 300).contains(response.response.statusCode) else {
      throw SnapperApiError.httpStatus(response.response.statusCode)
    }
    do {
      return try JSONDecoder().decode(Response.self, from: response.data)
    } catch {
      throw SnapperApiError.invalidResponse
    }
  }
}
