import Foundation
import SwiftData

protocol ApiClient {
  func health() async throws

  func searchAlbums(
    term: String?,
    barcode: String?,
    limit: Int,
  ) async throws -> [AlbumDto]

  func resolveTracks(
    discogsId: Int,
    barcode: String?,
  ) async throws -> TracklistResponseDto
}

struct NullApiClient: ApiClient {
  func health() async throws {}

  func searchAlbums(
    term: String?,
    barcode: String?,
    limit: Int,
  ) async throws -> [AlbumDto] {
    []
  }

  func resolveTracks(
    discogsId: Int,
    barcode: String?,
  ) async throws -> TracklistResponseDto {
    .empty
  }
}

struct SlowApiClient: ApiClient {
  func health() async throws {
    await sleepIndefinitely()
  }

  func searchAlbums(
    term: String?,
    barcode: String?,
    limit: Int,
  ) async throws -> [AlbumDto] {
    await sleepIndefinitely()
    return []
  }

  func resolveTracks(
    discogsId: Int,
    barcode: String?,
  ) async throws -> TracklistResponseDto {
    await sleepIndefinitely()
    return .empty
  }

  private func sleepIndefinitely() async {
    try? await Task.sleep(for: .seconds(9999))
  }
}

struct FailApiClient: ApiClient {
  func health() async throws {
    throw URLError(.notConnectedToInternet)
  }

  func searchAlbums(
    term: String?,
    barcode: String?,
    limit: Int,
  ) async throws -> [AlbumDto] {
    throw URLError(.notConnectedToInternet)
  }

  func resolveTracks(
    discogsId: Int,
    barcode: String?,
  ) async throws -> TracklistResponseDto {
    throw URLError(.notConnectedToInternet)
  }
}

struct StubApiClient: ApiClient {
  init(_ container: ModelContainer? = nil) {
    self.container = container ?? (try? SampleDataStore.makeContainer())
  }

  private let container: ModelContainer?

  private var albums: [Album] {
    guard let container else { return [] }
    let sortBy = SortDescriptor<Album>(\.selectedAt, order: .reverse)
    let fetch = FetchDescriptor<Album>(sortBy: [sortBy])
    let albums = try? container.mainContext.fetch(fetch)
    return albums ?? []
  }

  func health() async throws {}

  func searchAlbums(
    term: String?,
    barcode: String?,
    limit: Int,
  ) async throws -> [AlbumDto] {
    guard limit > 0 else { return [] }

    let matches = albums.filter { album in
      if let term, term.isEmpty == false {
        let matchesTitle = album.title.localizedStandardContains(term)
        let matchesArtist = album.artist.localizedStandardContains(term)
        return matchesTitle || matchesArtist
      }
      if let barcode, barcode.isEmpty == false {
        return album.barcode.contains(barcode)
      }
      return true
    }

    return
      matches
      .prefix(limit)
      .map(AlbumDto.fromModel)
  }

  func resolveTracks(
    discogsId: Int,
    barcode: String?,
  ) async throws -> TracklistResponseDto {
    let album = albums.first(where: { $0.discogsId == discogsId })
    let tracks = album?.tracks.map(TrackDto.fromModel) ?? []

    return TracklistResponseDto(
      albumUrl: nil,
      tracks: tracks,
    )
  }
}

extension ApiClient where Self == NullApiClient {
  static var null: Self { Self() }
}

extension ApiClient where Self == SlowApiClient {
  static var slow: Self { Self() }
}

extension ApiClient where Self == FailApiClient {
  static var fail: Self { Self() }
}

extension ApiClient where Self == StubApiClient {
  static var stub: Self { Self() }
  static func stub(_ container: ModelContainer) -> Self { Self(container) }
}
