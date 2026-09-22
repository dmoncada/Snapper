import Foundation

nonisolated struct AlbumTrack: Identifiable, Sendable, Hashable {
  let id: String
  let position: String?
  let title: String
  let duration: String?
  let previewUrl: URL?
}
