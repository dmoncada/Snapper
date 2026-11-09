import SwiftUI

struct ThemeSectionHeaderModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(Typography.section.header)
      .foregroundStyle(Color.themePrimary)
  }
}

extension View {
  func withThemeSectionHeaderStyle() -> some View {
    modifier(ThemeSectionHeaderModifier())
  }
}
