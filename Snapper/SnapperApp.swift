import SwiftData
import SwiftUI

@main
struct SnapperApp: App {
  @AppStorage(.storageKeys.firstLaunch) private var firstLaunch: Bool = true

  @State private var isLaunching = false

  var body: some Scene {
    WindowGroup {
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
      .modelContainer(for: AlbumEntry.self)
    }
  }
}
