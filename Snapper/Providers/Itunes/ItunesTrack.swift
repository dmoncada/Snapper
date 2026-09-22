import Foundation

nonisolated struct ItunesTrack: Identifiable, Sendable, Hashable {
  let id: Int
  let discNumber: Int
  let trackNumber: Int
  let title: String
  let duration: String?
  let previewUrl: URL?
}

nonisolated struct ItunesTracklist: Sendable, Hashable {
  let collectionId: Int
  let artist: String
  let title: String
  let collectionUrl: URL?
  let tracks: [ItunesTrack]
}
