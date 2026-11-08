import SwiftUI

struct ThemeLabeledContentStyle: LabeledContentStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
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
  static var withThemeFont: Self { Self() }
}
