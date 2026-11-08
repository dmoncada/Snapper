import SwiftUI

struct ThemeSectionFooterModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(Typography.sectionFooter)
      .foregroundStyle(Color.themeSecondary)
  }
}

extension View {
  func withThemeSectionFooterStyle() -> some View {
    modifier(ThemeSectionFooterModifier())
  }
}
