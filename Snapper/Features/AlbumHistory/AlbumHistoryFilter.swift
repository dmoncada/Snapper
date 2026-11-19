import Foundation

enum AlbumHistoryFilter: Hashable, Identifiable {
  case all
  case favorites
  case genre(String)

  var id: Self { self }

  var resource: LocalizedStringResource {
    switch self {
    case .all:
      .historyFiltersAll

    case .favorites:
      .historyFiltersFavorites

    case .genre(let genre):
      AlbumGenre(rawValue: genre)?.resource ?? .genresUnknown
    }
  }
}
