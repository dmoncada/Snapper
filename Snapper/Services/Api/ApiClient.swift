import Foundation

nonisolated protocol ApiClient: Sendable {
  func health() async throws

  func searchAlbums(
    term: String?,
    barcode: String?,
    limit: Int,
  ) async throws -> [AlbumDto]

  func resolveTracks(
    discogsId: Int,
    albumTitle: String,
    albumArtist: String,
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
    albumTitle: String,
    albumArtist: String,
    barcode: String?,
  ) async throws -> TracklistResponseDto {
    .init(
      albumUrl: nil,
      tracks: [],
    )
  }
}

extension ApiClient where Self == NullApiClient {
  static var null: Self { Self() }
}
