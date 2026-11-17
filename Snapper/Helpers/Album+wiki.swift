import Foundation

struct WikipediaInfo {
  var url: URL?
  var title: String?
  var extract: String?

  var hasInfo: Bool {
    url != nil && title != nil && extract != nil
  }
}

struct WikipediaInfoAccessor {
  private let getter: () -> WikipediaInfo
  private let setter: (WikipediaInfo) -> Void

  init(
    getter: @escaping () -> WikipediaInfo,
    setter: @escaping (WikipediaInfo) -> Void,
  ) {
    self.getter = getter
    self.setter = setter
  }

  func get() -> WikipediaInfo {
    getter()
  }

  func set(_ dto: WikipediaExtractDto) {
    setter(
      WikipediaInfo(
        url: dto.url,
        title: dto.title,
        extract: dto.extractMarkdown,
      )
    )
  }

  var hasInfo: Bool {
    getter().hasInfo
  }
}
extension Album {
  @MainActor
  var artistInfo: WikipediaInfoAccessor {
    WikipediaInfoAccessor(
      getter: {
        WikipediaInfo(
          url: self.wikipediaArtistUrl,
          title: self.wikipediaArtistTitle,
          extract: self.wikipediaArtistExtract,
        )
      },
      setter: {
        self.wikipediaArtistUrl = $0.url
        self.wikipediaArtistTitle = $0.title
        self.wikipediaArtistExtract = $0.extract
      },
    )
  }

  @MainActor
  var albumInfo: WikipediaInfoAccessor {
    WikipediaInfoAccessor(
      getter: {
        WikipediaInfo(
          url: self.wikipediaAlbumUrl,
          title: self.wikipediaAlbumTitle,
          extract: self.wikipediaAlbumExtract,
        )
      },
      setter: {
        self.wikipediaAlbumUrl = $0.url
        self.wikipediaAlbumTitle = $0.title
        self.wikipediaAlbumExtract = $0.extract
      },
    )
  }
}
