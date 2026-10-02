import SwiftUI

struct PlaybackIndicator: View {
  let isPlaying: Bool
  let progress: Double

  var body: some View {
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
}

#if DEBUG
#Preview {
  PlaybackIndicator(isPlaying: true, progress: 0.5)
    .frame(width: 24)
}
#endif
