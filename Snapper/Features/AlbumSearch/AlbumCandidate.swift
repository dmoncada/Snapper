import Foundation

nonisolated struct AlbumCandidate: Identifiable, Decodable, Sendable, Hashable {
  let id: Int
  let artist: String
  let title: String
  let year: Int?
  let formats: [String]
  let labels: [String]
  let country: String?
  let thumbnailUrl: URL?
  let coverImageUrl: URL?
  let discogsUrl: URL?
}
