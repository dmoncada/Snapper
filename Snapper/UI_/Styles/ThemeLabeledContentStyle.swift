import SwiftUI

struct ThemeLabeledContentStyle: LabeledContentStyle {
  let alignment: VerticalAlignment

  func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: alignment) {
      configuration.label
        .font(Typography.labelBody)
        .foregroundStyle(.primary)

      Spacer()

      configuration.content
        .font(Typography.labelBody)
        .foregroundStyle(.secondary)
    }
  }
}

extension LabeledContentStyle where Self == ThemeLabeledContentStyle {
  static var withThemeFont: Self {
    Self(alignment: .center)
  }

  static func withThemeFont(_ alignment: VerticalAlignment = .center) -> Self {
    Self(alignment: alignment)
  }
}
