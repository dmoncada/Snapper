import Foundation
import SwiftData

@Model
final class AlbumHistoryEntry {
  var id: UUID = UUID()
  var discogsReleaseId: Int
  var artist: String
  var title: String
  var year: Int?
  var formats: [String]
  var labels: [String]
  var country: String?
  var thumbnailUrlString: String?
  var discogsUrlString: String?
  var barcode: String?
  var selectedAt: Date
  var latitude: Double? = nil
  var longitude: Double? = nil
  var horizontalAccuracy: Double? = nil
  var locationCapturedAt: Date? = nil
  var locationLabel: String? = nil

  init(selection: AlbumSelection, selectedAt: Date = .now) {
    let candidate = selection.candidate
    id = UUID()
    discogsReleaseId = candidate.id
    artist = candidate.artist
    title = candidate.title
    year = candidate.year
    formats = candidate.formats
    labels = candidate.labels
    country = candidate.country
    thumbnailUrlString = candidate.thumbnailUrl?.absoluteString
    discogsUrlString = candidate.discogsUrl?.absoluteString
    barcode = selection.barcode
    self.selectedAt = selectedAt
  }

  var selection: AlbumSelection {
    let candidate = AlbumCandidate(
      id: discogsReleaseId,
      artist: artist,
      title: title,
      year: year,
      formats: formats,
      labels: labels,
      country: country,
      thumbnailUrl: thumbnailUrlString.flatMap(URL.init(string:)),
      discogsUrl: discogsUrlString.flatMap(URL.init(string:)))

    return AlbumSelection(candidate: candidate, barcode: barcode)
  }
}
