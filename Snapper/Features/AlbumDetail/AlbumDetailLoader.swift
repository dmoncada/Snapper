import Foundation

nonisolated struct AlbumDetailLoader: Sendable {
  private let itunesClient: ItunesClient
  private let discogsClient: DiscogsClient
  private let storefront: ItunesStorefront
  private let cache: AlbumDetailCache

  init(
    itunesClient: ItunesClient,
    discogsClient: DiscogsClient,
    storefront: ItunesStorefront,
    cache: AlbumDetailCache
  ) {
    self.itunesClient = itunesClient
    self.discogsClient = discogsClient
    self.storefront = storefront
    self.cache = cache
  }

  func load(_ selection: AlbumSelection) async throws -> AlbumDetail {
    let key = CacheKey(
      discogsReleaseId: selection.candidate.id,
      storefront: storefront)

    if let detail = await cache.detail(for: key) {
      return detail
    }

    let detail: AlbumDetail

    if let tracklist = try await itunesClient.tracklist(
      for: selection.candidate,
      barcode: selection.barcode)
    {
      detail = AlbumDetail(
        artist: tracklist.artist.isEmpty ? selection.candidate.artist : tracklist.artist,
        title: tracklist.title.isEmpty ? selection.candidate.title : tracklist.title,
        tracks: tracklist.tracks.map { track in
          AlbumTrack(
            id: "itunes-\(track.id)",
            position: "\(track.discNumber)-\(track.trackNumber)",
            title: track.title,
            duration: track.duration,
            previewUrl: track.previewUrl)
        },
        source: .itunes(tracklist.collectionUrl),
        discogsUrl: selection.candidate.discogsUrl)

    } else {
      let tracks = try await discogsClient.tracklist(forReleaseId: selection.candidate.id)
      detail = AlbumDetail(
        artist: selection.candidate.artist,
        title: selection.candidate.title,
        tracks: tracks,
        source: .discogs,
        discogsUrl: selection.candidate.discogsUrl)
    }

    await cache.store(detail, for: key)

    return detail
  }
}
