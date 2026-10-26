nonisolated struct TrackDto: Sendable, Codable {
  let id: Int?
  let title: String
  let position: String
  let duration: String
  let previewUrl: String?
}
