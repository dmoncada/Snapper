import AVFoundation
import SwiftUI

struct AlbumTrackRow: View {
  let track: AlbumTrack
  let artist: String
  let album: String
  let playback: PreviewPlaybackController

  var body: some View {
    HStack {
      if let position = track.position, position.count > 0 {
        Text(position)
          .foregroundStyle(.secondary)
      }

      VStack(alignment: .leading) {
        Text(track.title)

        if let duration = track.duration, duration.count > 0 {
          Text(duration)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        if playback.failedTrackId == track.id {
          Text("Preview unavailable. Try again.")
            .font(.subheadline)
            .foregroundStyle(.red)
        }
      }

      Spacer()

      if track.previewUrl != nil {
        if playback.currentTrack?.id == track.id,
          playback.isPlaying,
          playback.player?.currentItem?.status == .unknown
        {
          ProgressView()
        }

        if playback.currentTrack?.id == track.id && playback.isPlaying {
          Button("Pause Preview", systemImage: "pause.fill") {
            playback.pause()
          }
          .labelStyle(.iconOnly)
        } else {
          Button("Play Preview", systemImage: "play.fill") {
            playback.toggle(track, artist: artist, album: album)
          }
          .labelStyle(.iconOnly)
        }
      }
    }
  }
}
