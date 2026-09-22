import SwiftUI

struct AlbumTrackRow: View {
  let track: AlbumTrack

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
      }

      Spacer()

      if let previewUrl = track.previewUrl {
        Link("Preview", destination: previewUrl)
          .font(.subheadline)
      }
    }
  }
}
