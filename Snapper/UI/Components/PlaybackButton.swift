import SwiftUI

struct PlaybackButton: View {
  @Environment(\.isEnabled) private var isEnabled

  let isPlaying: Bool
  let action: () -> Void

  var body: some View {
    let title = isPlaying ? "Pause" : "play"

    let image =
      isEnabled
      ? isPlaying
        ? "pause.circle"
        : "play.circle"
      : "play.slash"

    Button(title, systemImage: image, action: action)
      .contentTransition(.symbolEffect)
      .labelStyle(.iconOnly)
      .imageScale(.large)
  }
}

#if DEBUG
  #Preview {
    @Previewable @State var isPlaying = false

    VStack(spacing: 8) {
      PlaybackButton(isPlaying: isPlaying) {
        isPlaying.toggle()
      }

      PlaybackButton(isPlaying: true) {}
        .tint(.themeRed)

      PlaybackButton(isPlaying: true) {}
        .disabled(true)
    }
  }
#endif
