import Foundation

nonisolated struct AlbumDetail: Sendable, Hashable {
  let artist: String
  let title: String
  let tracks: [AlbumTrack]
  let source: AlbumTracklistSource
  let discogsUrl: URL?
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
