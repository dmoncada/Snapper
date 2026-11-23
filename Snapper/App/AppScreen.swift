import SwiftUI

enum AppScreen: Codable, Hashable, Identifiable, CaseIterable {
  case search
  case history
  case spatial

  var id: AppScreen { self }
}

extension AppScreen {
  @ViewBuilder
  var label: some View {
    switch self {
    case .search:
      Label(.Search.title, systemImage: "house")

    case .history:
      Label(.History.title, systemImage: "clock")

    case .spatial:
      Label(.Spatial.title, systemImage: "map")
    }
  }

  @ViewBuilder
  var destination: some View {
    switch self {
    case .search:
      AlbumSearchView()

    case .history:
      AlbumHistoryView()

    case .spatial:
      AlbumMapView()
    }
  }
}
