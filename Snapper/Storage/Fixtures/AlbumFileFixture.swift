struct AlbumFixtureFile: Codable {
  var version: Int = 1
  var albums: [AlbumFixture]
}
