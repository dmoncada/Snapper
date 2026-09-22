import AVFoundation
import SwiftData
import SwiftUI

@main struct SnapperApp: App {
  init() {
    AVPlayer.isObservationEnabled = true
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(for: AlbumHistoryEntry.self)
  }
}
