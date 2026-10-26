import SwiftData
import SwiftUI

@main
struct SnapperApp: App {
  @State private var dependencies = Dependencies()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .modelContainer(dependencies.modelContainer)

        .environment(\.apiClient, dependencies.apiClient)
        .environment(\.previewPlayer, dependencies.previewPlayer)
        .environment(\.imageRecognizer, dependencies.imageRecognizer)
        .environment(\.locationProvider, dependencies.locationProvider)

        .environment(dependencies.searchViewModel)
        .environment(dependencies.historyViewModel)
        .environment(dependencies.locationCoordinator)
    }
  }
}

private struct ContentView: View {
  @AppStorage(.storageKeys.firstLaunch)
  private var firstLaunch = true

  @Environment(\.apiClient) private var client

  @State private var isLaunching = true

  var body: some View {
    TransitionView(
      showFirst: isLaunching,
      animation: .easeInOut,
    ) {
      LaunchView()
    } second: {
      SnapperAppShell()
    }
    .task {
      defer { firstLaunch = false }
      let delay = firstLaunch ? 2.0 : 0.5
      try? await Task.sleep(for: .seconds(delay))
      withAnimation { isLaunching = false }
    }
    .task {
      try? await client.health()  // Warm up the backend.
    }
  }
}
