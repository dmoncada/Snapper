import SwiftUI

struct RoundedOutlineButtonStyle: PrimitiveButtonStyle {
  let radius: CGFloat
  let lineWidth: CGFloat
  let color: Color

  init(
    radius: CGFloat = 4,
    lineWidth: CGFloat = 2,
    color: Color = .themePrimaryInverted
  ) {
    self.radius = radius
    self.lineWidth = lineWidth
    self.color = color
  }

  func makeBody(configuration: Configuration) -> some View {
    Button(configuration)
      .buttonBorderShape(.roundedRectangle(radius: radius))
      .roundedOutline(
        radius: radius,
        lineWidth: lineWidth,
        color: color
      )
  }
}

extension PrimitiveButtonStyle where Self == RoundedOutlineButtonStyle {
  static var roundedOutline: Self { Self() }
  static func roundedOutline(
    radius: CGFloat = 4,
    lineWidth: CGFloat = 2,
    color: Color = .primary
  ) -> Self {
    Self(
      radius: radius,
      lineWidth: lineWidth,
      color: color
    )
  }
}
