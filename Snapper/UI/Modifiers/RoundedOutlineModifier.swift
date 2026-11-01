import SwiftUI

struct RoundedOutlineModifier: ViewModifier {
  let radius: CGFloat
  let lineWidth: CGFloat
  let color: Color

  func body(content: Content) -> some View {
    content
      .clipShape(.rect(cornerRadius: radius))
      .overlay {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .strokeBorder(color, lineWidth: lineWidth)
      }
  }
}

extension View {
  func roundedOutline(
    radius: CGFloat = Radius.md,
    lineWidth: CGFloat = LineWidth.md,
    color: Color = .themePrimaryInverted,
  ) -> some View {
    modifier(
      RoundedOutlineModifier(
        radius: radius,
        lineWidth: lineWidth,
        color: color,
      )
    )
  }
}
