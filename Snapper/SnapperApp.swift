import SwiftData
import SwiftUI

@main struct SnapperApp: App {
  var body: some Scene {
    WindowGroup {
      SnapperAppShell()
        .modelContainer(for: AlbumEntry.self)
    }
  }
}
