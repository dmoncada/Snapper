import Foundation
import SwiftData

@Model
final class Track: Identifiable {
  @Attribute(.unique)
  var id: UUID

  var title: String
  var position: String
  var duration: String
  var previewUrl: URL?

  var album: Album?

  init(
    id: UUID = UUID(),
    title: String,
    position: String,
    duration: String,
    previewUrl: URL?,
    album: Album?,
  ) {
    self.id = id
    self.title = title
    self.position = position
    self.duration = duration
    self.previewUrl = previewUrl
    self.album = album
  }
}
