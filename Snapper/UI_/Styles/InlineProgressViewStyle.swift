import SwiftUI

struct InlineProgressViewStyle: ProgressViewStyle {
  enum ProgressPlacement {
    case leading
    case trailing
  }

  let placement: ProgressPlacement

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: Spacing.sm) {
      configuration.label
      ProgressView()
    }
  }
}

extension ProgressViewStyle where Self == InlineProgressViewStyle {
  static var inline: Self { Self(placement: .leading) }

  static func inline(_ placement: InlineProgressViewStyle.ProgressPlacement) -> Self {
    Self(placement: placement)
  }
}
