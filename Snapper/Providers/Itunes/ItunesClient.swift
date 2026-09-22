import Foundation
import OSLog

nonisolated struct ItunesClient: Sendable {
  private static let logger = Logger(subsystem: "net.dmoncada.Snapper", category: "itunes")

  private let storefront: ItunesStorefront
  private let transport: any HttpTransport

  init(storefront: ItunesStorefront = ItunesStorefront()) {
    self.init(
      storefront: storefront,
      transport: UrlSessionTransport()
        .withRateLimit()
        .withRetry())
  }

  init(storefront: ItunesStorefront, transport: any HttpTransport) {
    self.storefront = storefront
    self.transport = transport
  }

  func tracklist(for candidate: AlbumCandidate, barcode: String?) async throws -> ItunesTracklist? {
    do {
      if let barcode, !barcode.isEmpty, let collection = try await collection(forUpc: barcode) {
        Self.logger.info("Resolved iTunes collection through UPC lookup.")
        return try await tracks(for: collection)
      }

      let albumResults = try await request(
        path: "/search",
        queryItems: [
          URLQueryItem(name: "term", value: "\(candidate.artist) \(candidate.title)"),
          URLQueryItem(name: "media", value: "music"),
          URLQueryItem(name: "entity", value: "album"),
          URLQueryItem(name: "limit", value: "25"),
        ])
      if let collection = RecordLinkage.bestCollection(from: albumResults.results, for: candidate) {
        Self.logger.info("Resolved iTunes collection through album search.")
        return try await tracks(for: collection)
      }

      let artistResults = try await request(
        path: "/search",
        queryItems: [
          URLQueryItem(name: "term", value: candidate.artist),
          URLQueryItem(name: "media", value: "music"),
          URLQueryItem(name: "entity", value: "musicArtist"),
          URLQueryItem(name: "limit", value: "10"),
        ])
      guard
        let artist = RecordLinkage.bestArtist(from: artistResults.results, named: candidate.artist),
        let artistId = artist.artistId
      else {
        Self.logger.info("No confident iTunes artist match; using Discogs fallback.")
        return nil
      }

      let artistAlbums = try await request(
        path: "/lookup",
        queryItems: [
          URLQueryItem(name: "id", value: String(artistId)),
          URLQueryItem(name: "entity", value: "album"),
          URLQueryItem(name: "limit", value: "200"),
        ])
      guard
        let collection = RecordLinkage.bestCollection(from: artistAlbums.results, for: candidate)
      else {
        Self.logger.info(
          "No confident iTunes album match after artist lookup; using Discogs fallback.")
        return nil
      }

      Self.logger.info("Resolved iTunes collection through artist album lookup.")
      return try await tracks(for: collection)

    } catch is CancellationError {
      Self.logger.debug("iTunes tracklist resolution cancelled.")
      throw CancellationError()
    } catch {
      Self.logger.error(
        "iTunes resolution failed with \(String(reflecting: type(of: error)), privacy: .public).")
      throw error
    }
  }

  private func collection(forUpc barcode: String) async throws -> ItunesSearchResult? {
    let response = try await request(
      path: "/lookup",
      queryItems: [
        URLQueryItem(name: "upc", value: barcode),
        URLQueryItem(name: "entity", value: "song"),
      ])
    return response.results.first { $0.collectionId != nil }
  }

  private func tracks(for collection: ItunesSearchResult) async throws -> ItunesTracklist? {
    guard let collectionId = collection.collectionId else { return nil }
    let response = try await request(
      path: "/lookup",
      queryItems: [
        URLQueryItem(name: "id", value: String(collectionId)),
        URLQueryItem(name: "entity", value: "song"),
      ])
    let tracks = response.results.compactMap(ItunesTrack.init).sorted {
      ($0.discNumber, $0.trackNumber) < ($1.discNumber, $1.trackNumber)
    }
    guard !tracks.isEmpty else {
      Self.logger.info("iTunes collection returned no tracks; using Discogs fallback.")
      return nil
    }
    return ItunesTracklist(
      collectionId: collectionId,
      artist: collection.artistName ?? "",
      title: collection.collectionName ?? "",
      collectionUrl: collection.collectionViewUrl,
      tracks: tracks)
  }

  private func request(path: String, queryItems: [URLQueryItem]) async throws
    -> ItunesSearchResponse
  {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "itunes.apple.com"
    components.path = path
    components.queryItems =
      queryItems + [URLQueryItem(name: "country", value: storefront.countryCode)]
    guard let url = components.url else { throw ItunesClientError.invalidUrl }

    Self.logger.debug(
      "Starting iTunes request at \(path, privacy: .public) for storefront \(storefront.countryCode, privacy: .public)."
    )
    let httpResponse = try await transport.send(URLRequest(url: url))
    let statusCode = httpResponse.response.statusCode
    Self.logger.info("iTunes response: HTTP \(statusCode), \(httpResponse.data.count) bytes.")
    guard (200 ..< 300).contains(statusCode) else {
      throw ItunesClientError.unexpectedStatusCode(statusCode)
    }
    let response = try JSONDecoder().decode(ItunesSearchResponse.self, from: httpResponse.data)
    Self.logger.debug("Decoded \(response.results.count) iTunes results.")
    return response
  }
}

extension ItunesTrack {
  nonisolated fileprivate init?(_ result: ItunesSearchResult) {
    guard
      let id = result.trackId,
      let title = result.trackName,
      let trackNumber = result.trackNumber
    else { return nil }

    self.init(
      id: id,
      discNumber: result.discNumber ?? 1,
      trackNumber: trackNumber,
      title: title,
      duration: result.trackTimeMillis.map { milliseconds in
        let seconds = milliseconds / 1_000
        return "\(seconds / 60):\(String(seconds % 60).padded(to: 2, with: "0"))"
      },
      previewUrl: result.previewUrl)
  }
}

extension String {
  nonisolated fileprivate func padded(to length: Int, with character: Character) -> String {
    String(repeating: String(character), count: max(0, length - count)) + self
  }
}
