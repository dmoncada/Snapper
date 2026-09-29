import Foundation
import SwiftData

@Model
class AlbumEntry {
  var id: UUID = UUID()

  var discogsReleaseId: Int
  var artist: String
  var title: String
  var year: Int?
  var formats: [String]
  var labels: [String]
  var country: String?
  var thumbnailUrlString: String?
  var coverImageUrlString: String?
  var discogsUrlString: String?
  var selectedAt: Date

  var latitude: Double? = nil
  var longitude: Double? = nil

  init(candidate: AlbumCandidate, selectedAt: Date = .now) {
    id = UUID()
    discogsReleaseId = candidate.id
    artist = candidate.artist
    title = candidate.title
    year = candidate.year
    formats = candidate.formats
    labels = candidate.labels
    country = candidate.country
    thumbnailUrlString = candidate.thumbnailUrl?.absoluteString
    coverImageUrlString = candidate.coverImageUrl?.absoluteString
    discogsUrlString = candidate.discogsUrl?.absoluteString
    self.selectedAt = selectedAt
  }
}

extension AlbumEntry {
  func toCandidate() -> AlbumCandidate {
    AlbumCandidate(
      id: discogsReleaseId,
      artist: artist,
      title: title,
      year: year,
      formats: formats,
      labels: labels,
      country: country,
      thumbnailUrl: thumbnailUrlString.flatMap(URL.init(string:)),
      coverImageUrl: coverImageUrlString.flatMap(URL.init(string:)),
      discogsUrl: discogsUrlString.flatMap(URL.init(string:))
    )
  }
}
