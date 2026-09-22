import Foundation
import OSLog

nonisolated struct DiscogsClient: Sendable {
  private static let logger = Logger(subsystem: "net.dmoncada.Snapper", category: "discogs")

  private let token: String
  private let transport: any HttpTransport

  init(token: String) {
    self.init(
      token: token,
      transport: UrlSessionTransport()
        .withRateLimit()
        .withRetry())
  }

  init(token: String, transport: any HttpTransport) {
    self.token = token
    self.transport = transport
  }

  func searchAlbums(matching searchTerm: String, limit: Int = 5) async throws -> [AlbumCandidate] {
    let trimmedSearchTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedSearchTerm.isEmpty {
      throw DiscogsClientError.emptySearchTerm
    }

    return try await search(
      queryName: "q",
      queryValue: trimmedSearchTerm,
      limit: limit)
  }

  func searchAlbums(withBarcode barcode: String, limit: Int = 5) async throws -> [AlbumCandidate] {
    let trimmedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedBarcode.isEmpty {
      throw DiscogsClientError.emptySearchTerm
    }

    return try await search(
      queryName: "barcode",
      queryValue: trimmedBarcode,
      limit: limit)
  }

  func tracklist(forReleaseId releaseId: Int) async throws -> [AlbumTrack] {
    do {
      var components = URLComponents()
      components.scheme = "https"
      components.host = "api.discogs.com"
      components.path = "/releases/\(releaseId)"
      guard let url = components.url else {
        throw DiscogsClientError.invalidUrl
      }

      var request = URLRequest(url: url)
      request.setValue("Discogs token=\(token)", forHTTPHeaderField: "Authorization")
      request.setValue("Snapper/1.0", forHTTPHeaderField: "User-Agent")
      Self.logger.debug("Starting Discogs release tracklist request.")

      let httpResponse = try await transport.send(request)
      let statusCode = httpResponse.response.statusCode
      Self.logger.info(
        "Discogs release response: HTTP \(statusCode), \(httpResponse.data.count) bytes.")
      guard (200 ..< 300).contains(statusCode) else {
        throw DiscogsClientError.unexpectedStatusCode(statusCode)
      }

      let response = try JSONDecoder().decode(DiscogsReleaseResponse.self, from: httpResponse.data)
      let tracks = (response.tracklist ?? []).compactMap(AlbumTrack.init)
      Self.logger.debug("Mapped \(tracks.count) Discogs tracks.")
      return tracks

    } catch is CancellationError {
      Self.logger.debug("Discogs release tracklist request cancelled.")
      throw CancellationError()

    } catch {
      Self.logger.error(
        "Discogs release tracklist failed with \(String(reflecting: type(of: error)), privacy: .public)."
      )
      throw error
    }
  }

  private func search(queryName: String, queryValue: String, limit: Int) async throws
    -> [AlbumCandidate]
  {
    do {
      if token.isEmpty {
        throw DiscogsClientError.invalidToken
      }

      let request = try makeRequest(queryName: queryName, queryValue: queryValue, limit: limit)
      Self.logger.debug(
        "Starting Discogs \(queryName, privacy: .public) search at \(request.url?.path ?? "", privacy: .public)."
      )

      let httpResponse = try await transport.send(request)
      let statusCode = httpResponse.response.statusCode
      Self.logger.info(
        "Discogs response: HTTP \(statusCode), \(httpResponse.data.count) bytes.")

      guard (200 ..< 300).contains(statusCode) else {
        Self.logger.error("Discogs returned HTTP \(statusCode).")
        throw DiscogsClientError.unexpectedStatusCode(statusCode)
      }

      let response = try JSONDecoder().decode(DiscogsSearchResponse.self, from: httpResponse.data)
      Self.logger.debug("Mapped \(response.results.count) Discogs candidates.")
      return response.results.map(AlbumCandidate.init)

    } catch is CancellationError {
      Self.logger.debug("Discogs search cancelled.")
      throw CancellationError()

    } catch {
      Self.logger.error(
        "Discogs search failed with \(String(reflecting: type(of: error)), privacy: .public).")
      throw error
    }
  }

  private func makeRequest(queryName: String, queryValue: String, limit: Int) throws -> URLRequest {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "api.discogs.com"
    components.path = "/database/search"
    components.queryItems = [
      URLQueryItem(name: queryName, value: queryValue),
      URLQueryItem(name: "type", value: "release"),
      URLQueryItem(name: "per_page", value: String(min(max(limit, 1), 20))),
    ]

    guard let url = components.url else {
      throw DiscogsClientError.invalidUrl
    }

    var request = URLRequest(url: url)
    request.setValue("Discogs token=\(token)", forHTTPHeaderField: "Authorization")
    request.setValue("Snapper/1.0", forHTTPHeaderField: "User-Agent")
    return request
  }
}

extension AlbumTrack {
  nonisolated fileprivate init?(_ track: DiscogsTrackResponse) {
    guard track.type != "heading" else { return nil }
    self.init(
      id: "discogs-\(track.position ?? "")-\(track.title)",
      position: track.position,
      title: track.title,
      duration: track.duration,
      previewUrl: nil)
  }
}

extension AlbumCandidate {
  nonisolated fileprivate init(_ searchResult: DiscogsSearchResult) {
    if let separatorRange = searchResult.title.range(of: " - ") {
      artist = String(searchResult.title[..<separatorRange.lowerBound])
      title = String(searchResult.title[separatorRange.upperBound...])
    } else {
      artist = ""
      title = searchResult.title
    }

    id = searchResult.id
    year = searchResult.year.flatMap(Int.init)
    formats = searchResult.format ?? []
    labels = searchResult.label ?? []
    country = searchResult.country
    thumbnailUrl = searchResult.thumb.flatMap(URL.init(string:))
    discogsUrl = searchResult.uri.flatMap { URL(string: "https://www.discogs.com\($0)") }
  }
}
