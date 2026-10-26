import Foundation

struct AlbumFixture: Codable {
  var id: UUID
  var discogsId: Int

  var title: String
  var artist: String

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
  var isFavorite: Bool

  var tracks: [TrackFixture]

  init(album: Album) {
    id = album.id
    discogsId = album.discogsId
    title = album.title
    artist = album.artist

    discogsUrl = album.discogsUrl
    thumbnailUrl = album.thumbnailUrl
    coverImageUrl = album.coverImageUrl
    countryName = album.countryName
    countryCode = album.countryCode
    year = album.year

    format = album.format
    label = album.label
    genre = album.genre
    barcode = album.barcode

    selectedAt = album.selectedAt
    latitude = album.latitude
    longitude = album.longitude
    isFavorite = album.isFavorite

    tracks = album.tracks.map(TrackFixture.init)
  }

  func makeModel() -> Album {
    let album = Album(
      id: id,
      discogsId: discogsId,
      title: title,
      artist: artist,
      discogsUrl: discogsUrl,
      thumbnailUrl: thumbnailUrl,
      coverImageUrl: coverImageUrl,
      countryName: countryName,
      countryCode: countryCode,
      year: year,
      format: format,
      label: label,
      genre: genre,
      barcode: barcode,
      selectedAt: selectedAt,
    )

    album.latitude = latitude
    album.longitude = longitude
    album.isFavorite = isFavorite

    for fixture in tracks {
      let track = fixture.makeModel(album: album)
      album.tracks.append(track)
    }

    return album
  }
}
