import Foundation

enum AlbumHistoryFilter: Hashable, Identifiable {
  case all
  case favorites
  case genre(String)

  var id: Self { self }

  var title: String {
    switch self {
    case .all: "All"
    case .favorites: "Favorites"
    case .genre(let genre): genre
    }
  }
}
