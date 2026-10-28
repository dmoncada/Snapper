import SwiftUI

@MainActor
@Observable
final class AlbumDetailViewModel {
  enum State {
    case ready
    case loading
    case cancelled
    case success([Track])
    case failure(String)
    // case failure(LocalizedError)
  }

  // init(apiClient: any ApiClient = .null) {
  init(apiClient: any ApiClient = .live) {
    self.apiClient = apiClient
  }

  private(set) var state: State = .ready

  private let apiClient: ApiClient

  func resolveTracks(for album: Album) async {
    guard album.tracks.isEmpty else {
      state = .success(album.tracks.positionSorted)
      return
    }

    state = .loading

    do {
      let response = try await apiClient.resolveTracks(for: album)
      try Task.checkCancellation()

      guard album.tracks.isEmpty else {
        state = .success(album.tracks)
        return
      }

      album.musicUrl = response.albumUrl.flatMap(URL.init(string:))
      album.tracks = response.tracks.map { Track(dto: $0, album: album) }

      state = .success(album.tracks.positionSorted)
    } catch is CancellationError {
      state = .cancelled
    } catch {
      state = .failure(error.localizedDescription)
    }
  }
}

extension Array where Element == Track {
  fileprivate var positionSorted: [Track] {
    sorted(using: KeyPathComparator(\.position, comparator: .localizedStandard))
  }
}

extension ApiClient {
  fileprivate func resolveTracks(for album: Album) async throws -> TracklistResponseDto {
    try await resolveTracks(
      // discogsId: album.id,
      discogsId: album.discogsId,
      albumTitle: album.title,
      albumArtist: album.artist,
      barcode: album.barcode.first,
    )
  }
}
