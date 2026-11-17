import SwiftUI

struct StopPlayerOnUrl: ViewModifier {
  @Environment(\.previewPlayer) private var player

  func body(content: Content) -> some View {
    content
      .environment(
        \.openURL,
        OpenURLAction { url in
          Task {
            await player.stopImmediately()
          }

          return .systemAction
        },
      )
  }
}

extension View {
  func stopPlayerOnUrl() -> some View {
    modifier(StopPlayerOnUrl())
  }
}
