import Foundation

nonisolated struct DiscogsSearchResponse: Decodable, Sendable {
  let results: [DiscogsSearchResult]
}

nonisolated struct DiscogsSearchResult: Decodable, Sendable {
  let id: Int
  let title: String
  let year: String?
  let format: [String]?
  let label: [String]?
  let country: String?
  let thumb: String?
  let uri: String?

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case year
    case format
    case label
    case country
    case thumb
    case uri
  }
}

nonisolated struct DiscogsReleaseResponse: Decodable, Sendable {
  let tracklist: [DiscogsTrackResponse]?
}

nonisolated struct DiscogsTrackResponse: Decodable, Sendable {
  let position: String?
  let title: String
  let duration: String?
  let type: String?

  enum CodingKeys: String, CodingKey {
    case position
    case title
    case duration
    case type = "type_"
  }
}
