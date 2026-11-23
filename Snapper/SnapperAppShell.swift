import SwiftData
import SwiftUI

struct SnapperAppShell: View {
  @Environment(\.scenePhase) private var phase
  @Environment(\.modelContext) private var context

  @Environment(AlbumLocationCaptureCoordinator.self) private var locationCoordinator

  @Bindable var navigation: AppNavigation

  var body: some View {
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

private struct AppTabView: View {
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
