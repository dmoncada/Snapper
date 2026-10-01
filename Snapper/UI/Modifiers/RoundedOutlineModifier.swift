import SwiftUI

struct RoundedOutlineModifier: ViewModifier {
  var radius: CGFloat = Radius.md
  var lineWidth: CGFloat = LineWidth.md
  var color: Color = .themePrimaryInverted

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
