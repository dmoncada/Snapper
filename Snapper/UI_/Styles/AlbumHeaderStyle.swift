import SwiftUI

struct AlbumHeaderStyle: LabeledContentStyle {
  let controlSize: ControlSize

  private let defaultStyles: (Font.TextStyle, Font.TextStyle) = (
    .caption, .caption2,
  )

  private let styles: [ControlSize: (Font.TextStyle, Font.TextStyle)] = [
    .small: (.caption, .caption2),
    .large: (.headline, .subheadline),
  ]

  func makeBody(configuration: Configuration) -> some View {
    let (titleStyle, artistStyle) = styles[controlSize] ?? defaultStyles

    VStack(alignment: .leading, spacing: Spacing.xs) {
      configuration.label
        .font(.sligoilMicroBold(titleStyle))
        .foregroundStyle(.themePrimaryInverted)

      configuration.content
        .font(.sligoilMicro(artistStyle))
        .foregroundStyle(.accent)
    }
  }
}

extension LabeledContentStyle where Self == AlbumHeaderStyle {
  static var albumHeader: Self {
    AlbumHeaderStyle(controlSize: .small)
  }

  static func albumHeader(controlSize: ControlSize = .small) -> Self {
    AlbumHeaderStyle(controlSize: controlSize)
  }
}
