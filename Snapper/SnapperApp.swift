import AVFoundation
import SwiftUI

@main struct SnapperApp: App {
  init() {
    AVPlayer.isObservationEnabled = true
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
