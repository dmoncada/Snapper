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

extension AlbumDto {
  static func fromModel(_ model: Album) -> AlbumDto {
    AlbumDto(
      id: model.discogsId,
      title: model.title,
      artist: model.artist,

      discogsUrl: model.discogsUrl?.absoluteString,
      thumbnailUrl: model.thumbnailUrl?.absoluteString,
      coverImageUrl: model.coverImageUrl?.absoluteString,

      country: model.countryName,
      countryInfo: model.countryCode.map {
        CountryDto(
          alpha2: $0,
          alpha3: "",
          numeric: "",
          name: model.countryName ?? "",
          officialName: model.countryName ?? "",
        )
      },

      year: model.year,
      format: model.format,
      label: model.label,
      genre: model.genre,
      barcode: model.barcode,
    )
  }
}

extension TrackDto {
  static func fromModel(_ model: Track) -> TrackDto {
    TrackDto(
      id: model.id.hashValue,
      title: model.title,
      position: model.position,
      duration: model.duration,
      previewUrl: model.previewUrl?.absoluteString,
    )
  }
}
