#if DEBUG
import SwiftUI

struct WithColorSchemes<Content: View>: View {
  let content: Content
  let axis: Axis.Set

  init(
    axis: Axis.Set = .vertical,
    @ViewBuilder content: () -> Content,
  ) {
    self.axis = axis
    self.content = content()
  }

  var body: some View {
    VStack {
      if axis == .vertical {
        VStack(spacing: 0) {
          colorSchemePreview(.light)
          colorSchemePreview(.dark)
        }
      } else {
        HStack(spacing: 0) {
          colorSchemePreview(.light)
          colorSchemePreview(.dark)
        }
      }
    }
  }

  private func colorSchemePreview(_ scheme: ColorScheme) -> some View {
    content
      .background(.themeBackground)
      .environment(\.colorScheme, scheme)
  }
}
#endif
