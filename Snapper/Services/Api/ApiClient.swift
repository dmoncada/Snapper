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

  func fetchAlbumSummary(
    discogsId: Int
  ) async throws -> AlbumSummaryResponseDto
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

  func fetchAlbumSummary(
    discogsId: Int
  ) async throws -> AlbumSummaryResponseDto {
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

  func fetchAlbumSummary(
    discogsId: Int
  ) async throws -> AlbumSummaryResponseDto {
    await sleepIndefinitely()
    return .empty
  }

  private func sleepIndefinitely() async {
    try? await Task.sleep(for: .seconds(9999))
  }
}

struct FailApiClient: ApiClient {
  var error: Error { URLError(.notConnectedToInternet) }

  func health() async throws {
    throw error
  }

  func searchAlbums(
    term: String?,
    barcode: String?,
    limit: Int,
  ) async throws -> [AlbumDto] {
    throw error
  }

  func resolveTracks(
    discogsId: Int,
    barcode: String?,
  ) async throws -> TracklistResponseDto {
    throw error
  }

  func fetchAlbumSummary(
    discogsId: Int
  ) async throws -> AlbumSummaryResponseDto {
    throw error
  }
}

struct StubApiClient: ApiClient {
  init(_ container: ModelContainer, count: Int = 10) {
    self.container = container
    self.count = max(0, count)
  }

  private let container: ModelContainer
  private let count: Int

  private var albums: [Album] {
    let sortBy = SortDescriptor(\Album.selectedAt, order: .reverse)
    let fetch = FetchDescriptor(sortBy: [sortBy])
    let albums = try? container.mainContext.fetch(fetch)
    return albums ?? []
  }

  func health() async throws {}

  func searchAlbums(
    term: String?,
    barcode: String?,
    limit: Int,
  ) async throws -> [AlbumDto] {
    albums.prefix(min(limit, count)).map(AlbumDto.fromModel)
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

  func fetchAlbumSummary(
    discogsId: Int
  ) async throws -> AlbumSummaryResponseDto {
    .empty
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
  static func stub(_ container: ModelContainer, count: Int = 10) -> Self {
    Self(container, count: count)
  }
}
