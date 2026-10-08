import SwiftUI

nonisolated struct AlbumTracklistRequest: Encodable, Sendable {
  let discogsReleaseId: Int
  let artist: String
  let title: String
}

nonisolated struct AlbumTracklist: Sendable, Hashable {
  let tracks: [AlbumTrack]
  let source: AlbumTracklistSource
}

nonisolated enum AlbumTracklistSource: Sendable, Hashable {
  case itunes(URL?)
  case discogs

  var title: String {
    switch self {
    case .itunes:
      "Tracks and previews from iTunes"
    case .discogs:
      "Tracklist from Discogs"
    }
  }

  var itunesUrl: URL? {
    guard case .itunes(let url) = self else { return nil }
    return url
  }
}

nonisolated struct AlbumTracklistResolver: Sendable {
  private let apiClient: SnapperApiClient

  init(apiClient: SnapperApiClient) {
    self.apiClient = apiClient
  }

  func resolve(_ request: AlbumTracklistRequest) async throws -> AlbumTracklist {
    try await apiClient.resolveTracklist(request)
  }
}

@MainActor
@Observable
final class AlbumDetailViewModel {
  private let resolver: AlbumTracklistResolver

  private(set) var tracks: [AlbumTrack] = []
  private(set) var tracklistSource: AlbumTracklistSource?

  init() {
    resolver = .init(apiClient: .init())
  }

  func materialize(_ entry: AlbumEntry) async {
    let request = AlbumTracklistRequest(
      discogsReleaseId: entry.discogsReleaseId,
      artist: entry.artist,
      title: entry.title,
    )

    if let tracklist = await resolveTracks(for: request) {
      tracklistSource = tracklist.source
      tracks = tracklist.tracks
    }
  }

  private func resolveTracks(for entry: AlbumTracklistRequest) async -> AlbumTracklist? {
    do {
      return try await resolver.resolve(entry)
    } catch {
      return nil
    }
  }
}
