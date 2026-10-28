import Foundation
import SwiftData

@Model
final class Album: Identifiable {
  @Attribute(.unique)
  var id: UUID
  var discogsId: Int

  var title: String
  var artist: String

  var musicUrl: URL?
  var discogsUrl: URL?
  var thumbnailUrl: URL?
  var coverImageUrl: URL?

  var countryName: String?
  var countryCode: String?
  var year: Int?

  var format: [String]
  var label: [String]
  var genre: [String]
  var barcode: [String]

  var selectedAt: Date

  var latitude: Double?
  var longitude: Double?
  var locationStatusRaw: String?

  var isFavorite: Bool = false

  @Relationship(
    deleteRule: .cascade,
    inverse: \Track.album,
  )
  var tracks: [Track] = []

  init(
    id: UUID = UUID(),
    discogsId: Int,
    title: String,
    artist: String,
    discogsUrl: URL?,
    thumbnailUrl: URL?,
    coverImageUrl: URL?,
    countryName: String?,
    countryCode: String?,
    year: Int?,
    format: [String],
    label: [String],
    genre: [String],
    barcode: [String],
    selectedAt: Date,
  ) {
    self.id = id
    self.discogsId = discogsId
    self.title = title
    self.artist = artist
    self.discogsUrl = discogsUrl
    self.thumbnailUrl = thumbnailUrl
    self.coverImageUrl = coverImageUrl
    self.countryName = countryName
    self.countryCode = countryCode
    self.year = year
    self.format = format
    self.label = label
    self.genre = genre
    self.barcode = barcode
    self.selectedAt = selectedAt
  }
}
