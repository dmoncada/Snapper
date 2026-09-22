import SwiftUI

struct PreviewMiniPlayer: View {
  let playback: PreviewPlaybackController

  var body: some View {
    if let track = playback.currentTrack {
      HStack {
        VStack(alignment: .leading) {
          Text(track.title)
            .bold()
            .lineLimit(1)
          Text(playback.artist)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer()

        if playback.isPlaying {
          Button("Pause Preview", systemImage: "pause.fill") {
            playback.pause()
          }
          .labelStyle(.iconOnly)
        } else {
          Button("Play Preview", systemImage: "play.fill") {
            playback.resume()
          }
          .labelStyle(.iconOnly)
        }

        Button("Stop Preview", systemImage: "xmark") {
          playback.stop()
        }
        .labelStyle(.iconOnly)
      }
      .padding()
      .background(.regularMaterial)
    }
  }
}
