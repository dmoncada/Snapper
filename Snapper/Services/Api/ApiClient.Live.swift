/*
import Foundation

nonisolated struct LiveApiClient: ApiClient {
  private let httpClient: HttpClient

  init(
    baseUrl: URL = .baseUrl,
    transport: any HttpTransport = UrlSessionTransport().withRetry(),
  ) {
    httpClient = HttpClient(baseUrl: baseUrl, transport: transport)
  }

  func health() async throws {
    _ = try await httpClient.send(
      Endpoint<EmptyResponse>(
        route: .health,
        responseKind: .empty(EmptyResponse()),
      )
    )
  }

  func searchAlbums(
    term: String? = nil,
    barcode: String? = nil,
    limit: Int = 10,
  ) async throws -> [AlbumDto] {
    assert(term != nil || barcode != nil, "Term and barcode cannot both be nil.")

    let albums = try await searchAlbumsInternal(term, barcode, limit)

    if barcode != nil, let countryCode = Locale.current.region?.identifier {
      return AlbumRanking.preferredCountryFirst(albums, countryCode)
    }

    return albums
  }

  private func searchAlbumsInternal(
    _ term: String? = nil,
    _ barcode: String? = nil,
    _ limit: Int = 10,
  ) async throws -> [AlbumDto] {
    try await httpClient.send(
      Endpoint(
        route: .albums,
        queryItems: [
          URLQueryItem(name: "term", value: term),
          URLQueryItem(name: "barcode", value: barcode),
          URLQueryItem(name: "limit", value: String(limit)),
        ],
      )
    )
  }

  func resolveTracks(
    discogsId: Int,
    albumTitle: String,
    albumArtist: String,
    barcode: String? = nil,
  ) async throws -> [TrackDto] {
    try await httpClient.send(
      Endpoint(
        route: .tracks,
        queryItems: [
          URLQueryItem(name: "discogs_id", value: String(discogsId)),
          URLQueryItem(name: "album_title", value: albumTitle),
          URLQueryItem(name: "album_artist", value: albumArtist),
          URLQueryItem(name: "barcode", value: barcode),
        ],
      )
    )
  }
}

nonisolated private enum AlbumRanking {
  static func preferredCountryFirst(
    _ albums: [AlbumDto],
    _ countryCode: String,
  ) -> [AlbumDto] {
    let code = countryCode.uppercased()
    let local = albums.filter { $0.countryInfo?.alpha2.uppercased() == code }
    let other = albums.filter { $0.countryInfo?.alpha2.uppercased() != code }
    return local + other
  }
}

extension ApiClient where Self == LiveApiClient {
  static var live: Self { Self() }
  static func live(_ baseUrl: URL) -> Self { Self(baseUrl: baseUrl) }
}

#if DEBUG
import Playgrounds

#Playground("Search albums API") {
  let client: ApiClient = .live

  _ = try await client.searchAlbums(
    term: nil,
    barcode: "843563174807",
    limit: 10,
  )
}

#Playground("Resolve tracks API") {
  let client: ApiClient = .live

  _ = try await client.resolveTracks(
    discogsId: 25_875_376,
    albumTitle: "Time's Arrow",
    albumArtist: "Ladytron",
    barcode: "711297532685",
  )
}
#endif
*/
