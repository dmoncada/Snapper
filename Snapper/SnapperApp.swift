import SwiftData
import SwiftUI

@main
struct SnapperApp: App {
  @AppStorage(.storageKeys.firstLaunch) private var firstLaunch: Bool = true

  @State private var isLaunching = false

  private let store: Result<ModelContainer, Error> = Result {
    try SharedAlbumStore.makeContainer()
  }

  var body: some Scene {
    WindowGroup {
      switch store {
      case .success(let container):
        TransitionView(
          showFirst: isLaunching,
          animation: .easeInOut(duration: 0.5),
        ) {
          LaunchView()
        } second: {
          SnapperAppShell()
        }
        /*
        .task {
          defer { firstLaunch = false }
          let delay = firstLaunch ? 2 : 0.5
          try? await Task.sleep(for: .seconds(delay))
          withAnimation { isLaunching = false }
        }
         */
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
