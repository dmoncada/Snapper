import Foundation

enum AlbumHistoryFilter: Hashable, Identifiable {
  case all
  case favorites
  case genre(String)

  var id: Self { self }

  var resource: LocalizedStringResource {
    switch self {
    case .all:
      .filtersAll

    case .favorites:
      .filtersFavorites

    case .genre(let genre):
      AlbumGenre(rawValue: genre)?.resource ?? .genresUnknown
    }
  }
}
