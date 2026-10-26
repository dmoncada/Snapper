import Foundation

extension Album {
  convenience init(
    dto: AlbumDto,
    selectedAt: Date = .now,
  ) {
    self.init(
      id: UUID(),
      // discogsId: dto.discogsId,
      discogsId: dto.id,
      title: dto.title,
      artist: dto.artist,
      discogsUrl: dto.discogsUrl.flatMap(URL.init(string:)),
      thumbnailUrl: dto.thumbnailUrl.flatMap(URL.init(string:)),
      coverImageUrl: dto.coverImageUrl.flatMap(URL.init(string:)),
      countryName: dto.countryInfo?.name ?? dto.country,
      countryCode: dto.countryInfo?.alpha2,
      year: dto.year,
      format: dto.format,
      label: dto.label,
      genre: dto.genre,
      barcode: dto.barcode,
      selectedAt: selectedAt,
    )
  }
}

extension Track {
  convenience init(
    dto: TrackDto,
    album: Album,
  ) {
    self.init(
      id: UUID(),
      title: dto.title,
      position: dto.position,
      duration: dto.duration,
      previewUrl: dto.previewUrl.flatMap(URL.init(string:)),
      album: album,
    )
  }
}
