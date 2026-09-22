import Foundation

nonisolated struct ItunesSearchResponse: Decodable, Sendable {
  let results: [ItunesSearchResult]
}

nonisolated struct ItunesSearchResult: Decodable, Sendable {
  let wrapperType: String?
  let artistId: Int?
  let artistName: String?
  let collectionId: Int?
  let collectionName: String?
  let collectionViewUrl: URL?
  let trackId: Int?
  let trackName: String?
  let trackNumber: Int?
  let discNumber: Int?
  let trackTimeMillis: Int?
  let previewUrl: URL?
}
