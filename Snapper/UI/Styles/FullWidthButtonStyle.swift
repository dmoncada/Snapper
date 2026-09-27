import SwiftUI

struct FullWidthButtonStyle: PrimitiveButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button(action: { configuration.trigger() }) {
      configuration.label
        .frame(maxWidth: .infinity)
        .padding(.vertical, Padding.xl)
    }
  }
}

extension PrimitiveButtonStyle where Self == FullWidthButtonStyle {
  static var fullWidth: Self { Self() }
}
