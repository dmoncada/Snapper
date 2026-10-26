import Foundation

struct TrackFixture: Codable {
  var id: UUID
  var title: String
  var position: String
  var duration: String
  var previewUrl: URL?

  init(track: Track) {
    id = track.id
    title = track.title
    position = track.position
    duration = track.duration
    previewUrl = track.previewUrl
  }

  func makeModel(album: Album) -> Track {
    Track(
      id: id,
      title: title,
      position: position,
      duration: duration,
      previewUrl: previewUrl,
      album: album,
    )
  }
}
