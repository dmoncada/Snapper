import SwiftUI

struct PlaybackIndicator: View {
  @Environment(\.isEnabled) var isEnabled

  @ScaledMetric(relativeTo: .body) var scaledSize: CGFloat = 24
  @ScaledMetric(relativeTo: .body) var scaledWidth: CGFloat = 2

  let isPlaying: Bool
  let progress: Double

  var body: some View {
    ZStack {
      if isEnabled {
        Circle()
          .fill(.clear)
          .stroke(.secondary.opacity(0.5), lineWidth: scaledWidth)

        Circle()
          .trim(from: 0, to: isPlaying ? progress : 1)
          .stroke(style: StrokeStyle(lineWidth: scaledWidth, lineCap: .round))
          .rotationEffect(.degrees(-90))
      }
    }
    .overlay {
      Image(
        systemName:
          isEnabled
          ? isPlaying
            ? "pause.fill"
            : "play.fill"
          : "play.slash"
      )
      .contentTransition(.symbolEffect)
      .scaleEffect(isEnabled ? 0.75 : 1)
    }
    .frame(
      width: scaledSize,
      height: scaledSize,
    )
  }
}

#if DEBUG
struct TestPlaybackIndicator: View {
  @State private var isPlaying = false
  @State private var startDate: Date?

  private let duration: TimeInterval = 5

  private func play() {
    startDate = .now
    isPlaying = true
  }

  private func stop() {
    isPlaying = false
    startDate = nil
  }

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
      let progress: Double = {
        guard isPlaying, let startDate else { return 0 }
        return min(context.date.timeIntervalSince(startDate) / duration, 1)
      }()

      Button {
        isPlaying ? stop() : play()
      } label: {
        HStack(spacing: Spacing.sm) {
          PlaybackIndicator(isPlaying: isPlaying, progress: progress)
            // .frame(minWidth: 32)
            .border(.green)

          Text("Song")
            .lineLimit(1)
            .border(.blue)

          Spacer()

          Text("5:35")
            .border(.blue)
        }
        .contentShape(.rect)
      }
      .buttonStyle(.plain)
      .onChange(of: progress >= 1) { _, finished in
        guard finished, isPlaying else { return }
        stop()
      }
    }
  }
}

#Preview {
  @Previewable @State var isPlaying = false

  VStack(spacing: Spacing.sm) {
    TestPlaybackIndicator()
    TestPlaybackIndicator()
    TestPlaybackIndicator()
      .disabled(true)
  }
  .padding()
}
#endif
