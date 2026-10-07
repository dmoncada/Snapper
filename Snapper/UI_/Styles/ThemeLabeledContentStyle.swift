import SwiftUI

struct ThemeLabeledContentStyle: LabeledContentStyle {
  let isActive: Bool

  init(isActive: Bool = false) {
    self.isActive = isActive
  }

  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.label
        .font(.sligoilMicroBold(.subheadline))

      Spacer()

      configuration.content
        .font(.sligoilMicro(.subheadline))
    }
    .contentShape(.rect)
    .foregroundStyle(
      isActive
        ? .accent
        : .themePrimaryInverted
    )
    .opacity(0.625)
  }
}

extension LabeledContentStyle where Self == ThemeLabeledContentStyle {
  static var withThemeFont: Self {
    Self(isActive: false)
  }

  static func withThemeFont(isActive: Bool = false) -> Self {
    Self(isActive: isActive)
  }
}
