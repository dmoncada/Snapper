import Foundation

nonisolated struct ApiTracklistResponse: Decodable, Sendable {
  let source: String
  let itunesUrl: URL?
  let tracks: [AlbumTrack]
}
