import Foundation

nonisolated struct AlbumDto: Sendable, Codable {
  // var id: Int { discogsId }
  // let discogsId: Int

  let id: Int
  let title: String
  let artist: String

  let discogsUrl: String?
  let thumbnailUrl: String?
  let coverImageUrl: String?
  let country: String?
  let countryInfo: CountryDto?
  let year: Int?

  let format: [String]
  let label: [String]
  let genre: [String]
  let barcode: [String]
}

nonisolated struct CountryDto: Sendable, Codable {
  let alpha2: String
  let alpha3: String
  let numeric: String
  let name: String
  let officialName: String?
}
