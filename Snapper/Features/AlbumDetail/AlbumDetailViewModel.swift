import CoreLocation
import SwiftUI

nonisolated struct AlbumTracklistRequest: Sendable {
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
  private let discogsClient: DiscogsClient
  private let itunesClient: ItunesClient

  init(
    discogsClient: DiscogsClient,
    itunesClient: ItunesClient,
  ) {
    self.discogsClient = discogsClient
    self.itunesClient = itunesClient
  }

  func resolve(_ request: AlbumTracklistRequest) async throws -> AlbumTracklist {
    let candidate = AlbumCandidate(
      id: 0,
      artist: request.artist,
      title: request.title,
      year: nil,
      formats: [],
      labels: [],
      country: nil,
      thumbnailUrl: nil,
      coverImageUrl: nil,
      discogsUrl: nil,
    )

    if let tracklist = try await itunesClient.tracklist(for: candidate, barcode: nil) {
      return AlbumTracklist(
        tracks: tracklist.tracks.map { track in
          AlbumTrack(
            id: "itunes-\(track.id)",
            position: "\(track.discNumber)-\(track.trackNumber)",
            title: track.title,
            duration: track.duration,
            previewUrl: track.previewUrl,
          )
        },
        source: .itunes(tracklist.collectionUrl),
      )
    }

    let tracks = try await discogsClient.tracklist(for: request.discogsReleaseId)

    return AlbumTracklist(tracks: tracks, source: .discogs)
  }
}

@MainActor
@Observable
final class AlbumDetailViewModel {
  enum LocationState: Sendable, Equatable {
    case unavailable
    case resolving
    case resolved(CLLocation)
  }

  private let resolver: AlbumTracklistResolver
  private let locator: LocationService

  private(set) var tracks: [AlbumTrack] = []
  private(set) var tracklistSource: AlbumTracklistSource?
  private(set) var locationState: LocationState = .unavailable

  init() {
    let token = Bundle.main.object(forInfoDictionaryKey: "DISCOGS_TOKEN") as? String ?? ""

    resolver = .init(
      discogsClient: .init(token: token),
      itunesClient: .init(),
    )

    locator = .init()
  }

  func materialize(_ entry: AlbumEntry) async {
    let request = AlbumTracklistRequest(
      discogsReleaseId: entry.discogsReleaseId,
      artist: entry.artist,
      title: entry.title,
    )

    async let tracklist = resolveTracks(for: request)
    async let location = resolveLocation()

    if let tracklist = await tracklist {
      tracklistSource = tracklist.source
      tracks = tracklist.tracks
    }

    if let location = await location {
      locationState = .resolved(location)
    } else {
      locationState = .unavailable
    }
  }

  private func resolveTracks(for entry: AlbumTracklistRequest) async -> AlbumTracklist? {
    do {
      return try await resolver.resolve(entry)
    } catch {
      return nil
    }
  }

  private func resolveLocation() async -> CLLocation? {
    locationState = .resolving

    do {
      return try await locator.getLocation()
    } catch { return nil }
  }

  private func consumeTracks(_ task: Task<AlbumTracklist?, Never>) async {
    guard let tracklist = await task.value else {
      return
    }

    tracklistSource = tracklist.source
    tracks = tracklist.tracks
  }

  private func consumeLocation(_ task: Task<CLLocation?, Never>) async {
    guard let location = await task.value else {
      locationState = .unavailable
      return
    }

    locationState = .resolved(location)
  }
}
