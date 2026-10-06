import SwiftData
import SwiftUI

@main
struct SnapperApp: App {
  private let store: Result<ModelContainer, Error> = Result {
    if ProcessInfo.processInfo.arguments.contains("-ui-testing-seed-albums") {
      return try SampleAlbumStore.makeContainer(limit: 2)
    }
    return try SharedAlbumStore.makeContainer()
  }

  var body: some Scene {
    WindowGroup {
      switch store {
      case .success(let container):
        ContentView()
          .modelContainer(container)

      case .failure:
        ContentUnavailableView(
          "History unavailable",
          systemImage: "exclamationmark.triangle",
        )
      }
    }
  }
}

private struct ContentView: View {
  @AppStorage(.storageKeys.firstLaunch)
  private var firstLaunch = true

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
  }
}
