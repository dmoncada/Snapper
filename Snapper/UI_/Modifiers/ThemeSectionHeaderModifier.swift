import SwiftUI

struct ThemeSectionHeaderModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.libreCaslonTextBold(.headline))
      .foregroundStyle(.themePrimaryInverted)
  }
}

extension View {
  func withThemeSectionHeader() -> some View {
    modifier(ThemeSectionHeaderModifier())
  }
}
