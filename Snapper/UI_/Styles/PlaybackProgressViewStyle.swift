import SwiftUI

struct PlaybackProgressViewStyle: ProgressViewStyle {
  @Environment(\.isEnabled) private var isEnabled

  @ScaledMetric(relativeTo: .body) private var scaledSize: CGFloat = 24
  @ScaledMetric(relativeTo: .body) private var scaledWidth: CGFloat = 2

  let isPlaying: Bool

  func makeBody(configuration: Configuration) -> some View {
    ZStack {
      if isEnabled {
        Circle()
          .fill(.clear)
          .stroke(.secondary.opacity(0.25), lineWidth: scaledWidth)

        Circle()
          .trim(
            from: 0,
            to: isPlaying ? (configuration.fractionCompleted ?? 0) : 1,
          )
          .stroke(
            .primary,
            style: StrokeStyle(
              lineWidth: scaledWidth,
              lineCap: .round,
            ),
          )
          .rotationEffect(.degrees(-90))
      }

      Image(
        systemName: isEnabled
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

extension ProgressViewStyle where Self == PlaybackProgressViewStyle {
  static func playback(isPlaying: Bool) -> Self {
    Self(isPlaying: isPlaying)
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
          ProgressView(value: progress)
            .progressViewStyle(.playback(isPlaying: isPlaying))
            .border(.green)

          LabeledContent("Song", value: "5:35")
        }
        .contentShape(.rect)
      }
      .foregroundStyle(
        isPlaying ? .accent : .themePrimary,
        isPlaying ? .accent : .themeSecondary,
      )
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
