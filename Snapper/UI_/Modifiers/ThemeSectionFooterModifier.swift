import SwiftUI

struct ThemeSectionFooterModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.libreCaslonTextRegular(.footnote))
      .foregroundStyle(.themePrimaryInverted)
  }
}

extension View {
  func withThemeSectionFooter() -> some View {
    modifier(ThemeSectionFooterModifier())
  }
}
