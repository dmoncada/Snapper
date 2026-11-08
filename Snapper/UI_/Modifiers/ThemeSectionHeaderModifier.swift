import SwiftUI

struct ThemeSectionHeaderModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(Typography.sectionHeader)
      .foregroundStyle(Color.themePrimary)
  }
}

extension View {
  func withThemeSectionHeaderStyle() -> some View {
    modifier(ThemeSectionHeaderModifier())
  }
}
