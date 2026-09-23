import AVFoundation
import SwiftUI

struct ContentView: View {
  @State private var playback = PreviewPlaybackController()

  var body: some View {
    TabView {
      Tab("Recog", systemImage: "viewfinder") {
        RecognitionView(playback: playback)
      }

      Tab("History", systemImage: "clock.arrow.circlepath") {
        AlbumHistoryView(playback: playback)
      }
    }
    .safeAreaInset(edge: .bottom) {
      PreviewMiniPlayer(playback: playback)
    }
    .task(id: playback.itemIdentifier) {
      await playback.observeItemEnd()
    }
    .task(id: playback.itemIdentifier) {
      await playback.observeItemFailure()
    }
    .onChange(of: playback.player?.currentItem?.status) { _, status in
      Task { await playback.handleItemStatus(status) }
    }
    .onChange(of: playback.player?.timeControlStatus) {
      playback.updateNowPlaying()
    }
    .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) {
      _ in
      playback.pause()
    }
  }
}

#Preview {
  ContentView()
}
