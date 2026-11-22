import SwiftData
import SwiftUI

struct SnapperAppShell: View {
  @Environment(\.scenePhase) private var phase
  @Environment(\.modelContext) private var context

  @Environment(AlbumLocationCaptureCoordinator.self) private var locationCoordinator

  @State private var navigation = AppNavigation()

  var body: some View {
    @Bindable var navigation = navigation

    AppTabView(selection: $navigation.screen)
      .environment(\.navigation, navigation)
      .onChange(of: phase, initial: true) { _, next in
        switch next {
        case .active:
          locationCoordinator.resumePending(in: context)

        case .inactive:
          break
        case .background:
          break
        @unknown default:
          break
        }
      }
  }
}

struct AppTabView: View {
  @Binding var selection: AppScreen

  var body: some View {
    TabView(selection: $selection) {
      ForEach(AppScreen.allCases) { screen in
        Tab(value: screen) {
          screen.destination
        } label: {
          screen.label
        }
      }
    }
  }
}

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
