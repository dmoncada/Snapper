import Foundation

nonisolated struct WikipediaExtractDto: Sendable, Decodable {
  let title: String
  let extract: String
  let extractMarkdown: String
  let url: URL
}

nonisolated struct AlbumSummaryResponseDto: Sendable, Decodable {
  let album: WikipediaExtractDto?
  let artist: WikipediaExtractDto?

  static let empty = Self(album: nil, artist: nil)
}
