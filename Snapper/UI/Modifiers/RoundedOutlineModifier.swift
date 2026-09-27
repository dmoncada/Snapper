import SwiftUI

struct RoundedOutlineModifier: ViewModifier {
  var radius: CGFloat = 4
  var lineWidth: CGFloat = 2
  var color: Color = .primary

  func body(content: Content) -> some View {
    content
      .overlay {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .strokeBorder(color, lineWidth: lineWidth)
      }
  }
}

extension View {
  func roundedOutline(
    radius: CGFloat = 4,
    lineWidth: CGFloat = 2,
    color: Color = .primary
  ) -> some View {
    modifier(
      RoundedOutlineModifier(
        radius: radius,
        lineWidth: lineWidth,
        color: color
      )
    )
  }
}
