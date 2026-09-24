import Foundation

nonisolated struct AlbumCandidate: Identifiable, Sendable, Hashable {
  let id: Int
  let artist: String
  let title: String
  let year: Int?
  let formats: [String]
  let labels: [String]
  let country: String?
  let thumbnailUrl: URL?
  let discogsUrl: URL?

  var displayMetadata: String {
    [
      year.map(String.init),
      formats.first,
      country,
    ]
    .compactMap(\.self)
    .joined(separator: " • ")
  }
}
