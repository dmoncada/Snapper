import SwiftUI

struct FullBackgroundModifier<Background: ShapeStyle>: ViewModifier {
  let background: Background

  func body(content: Content) -> some View {
    ZStack {
      Rectangle()
        .fill(background)
        .ignoresSafeArea()

      content
    }
  }
}

extension View {
  func fullBackground<Background: ShapeStyle>(_ background: Background) -> some View {
    modifier(FullBackgroundModifier(background: background))
  }
}
