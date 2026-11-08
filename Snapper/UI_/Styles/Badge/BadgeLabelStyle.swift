import SwiftUI

struct BadgeLabelStyle<
  TextStyle: ShapeStyle,
  IconStyle: ShapeStyle,
  LineStyle: ShapeStyle,
  FillStyle: ShapeStyle,
>: LabelStyle {
  @Environment(\.controlSize) private var controlSize

  private let textStyle: TextStyle
  private let iconStyle: IconStyle
  private let lineStyle: LineStyle
  private let fillStyle: FillStyle

  init(
    textStyle: TextStyle = .themePrimary,
    iconStyle: IconStyle = .themePrimary,
    lineStyle: LineStyle = .themeSeparator,
    fillStyle: FillStyle = .clear,
  ) {
    self.textStyle = textStyle
    self.iconStyle = iconStyle
    self.lineStyle = lineStyle
    self.fillStyle = fillStyle
  }

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: Spacing.xs) {
      configuration.icon
        .foregroundStyle(iconStyle)

      configuration.title
        .foregroundStyle(textStyle)
    }
    .padding(Padding.md)
    .font(Typography.badge(for: controlSize))
    .background {
      RoundedRectangle(cornerRadius: Radius.md)
        .fill(fillStyle)
        .stroke(lineStyle, lineWidth: LineWidth.sm)
    }
  }
}

extension LabelStyle
where
  Self == BadgeLabelStyle<
    Color,
    Color,
    Color,
    Color
  >
{
  static var badge: Self {
    Self()
  }

  static func badge(
    textStyle: Color = .themePrimary,
    iconStyle: Color = .themePrimary,
    lineStyle: Color = .themeSeparator,
    fillStyle: Color = .clear,
  ) -> Self {
    Self(
      textStyle: textStyle,
      iconStyle: iconStyle,
      lineStyle: lineStyle,
      fillStyle: fillStyle,
    )
  }
}

#if DEBUG
#Preview {
  WithColorSchemes {
    VStack {
      Label("Label", systemImage: "checkmark")
        .labelStyle(.badge)
        .controlSize(.small)

      Label("Label", systemImage: "checkmark")
        .labelStyle(
          .badge(
            textStyle: .themeRed,
            iconStyle: .themeGreen,
            lineStyle: .themeRed,
            fillStyle: .themeYellow,
          )
        )
        .controlSize(.large)
    }
    .padding()
  }
}
#endif
