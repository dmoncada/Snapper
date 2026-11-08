import SwiftUI

struct RoundedOutlineModifier<LineStyle: ShapeStyle>: ViewModifier {
  let radius: CGFloat
  let lineWidth: CGFloat
  let lineStyle: LineStyle

  func body(content: Content) -> some View {
    content
      .clipShape(.rect(cornerRadius: radius))
      .overlay {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .strokeBorder(lineStyle, lineWidth: lineWidth)
      }
  }
}

extension View {
  func roundedOutline<LineStyle: ShapeStyle>(
    radius: CGFloat = Radius.md,
    lineWidth: CGFloat = LineWidth.md,
    lineStyle: LineStyle = .themeSeparator,
  ) -> some View {
    modifier(
      RoundedOutlineModifier(
        radius: radius,
        lineWidth: lineWidth,
        lineStyle: lineStyle,
      )
    )
  }
}
