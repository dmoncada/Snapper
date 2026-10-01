import SwiftUI

struct PlaybackButton: View {
  let isPlaying: Bool
  let progress: Double
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        Circle()
          .stroke(.secondary.opacity(0.5), lineWidth: LineWidth.md)

        Circle()
          .trim(from: 0, to: isPlaying ? progress : 1)
          .stroke(style: StrokeStyle(lineWidth: LineWidth.md, lineCap: .round))
          .rotationEffect(.degrees(-90))

        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
          .contentTransition(.symbolEffect)
          .scaleEffect(0.75)
      }
      .aspectRatio(1, contentMode: .fit)
    }
    .contentShape(Circle())
  }
}

#if DEBUG
#Preview {
  @Previewable @State var isPlaying = true
  @Previewable @State var progress = 0.25

  VStack(spacing: 20) {
    Group {
      PlaybackButton(isPlaying: isPlaying, progress: progress) {
        isPlaying.toggle()
      }
      .frame(width: 48, height: 48)

      PlaybackButton(isPlaying: true, progress: 0.5) {}
        .frame(width: 32, height: 32)

      PlaybackButton(isPlaying: false, progress: 0.75) {}
        .frame(width: 24, height: 24)
        .tint(.themeRed)

      PlaybackButton(isPlaying: false, progress: 1) {}
        .frame(width: 24, height: 24)
        .disabled(true)
    }
  }
}
#endif
