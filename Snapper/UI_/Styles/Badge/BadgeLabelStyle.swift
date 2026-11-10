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
  private let iconPlacement: IconPlacement

  init(
    textStyle: TextStyle = .themePrimary,
    iconStyle: IconStyle = .themePrimary,
    lineStyle: LineStyle = .themeSeparator,
    fillStyle: FillStyle = .clear,
    iconPlacement: IconPlacement = .leading,
  ) {
    self.textStyle = textStyle
    self.iconStyle = iconStyle
    self.lineStyle = lineStyle
    self.fillStyle = fillStyle
    self.iconPlacement = iconPlacement
  }

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: Spacing.xs) {
      if iconPlacement == .leading {
        configuration.icon
          .foregroundStyle(iconStyle)
      }

      configuration.title
        .foregroundStyle(textStyle)

      if iconPlacement == .trailing {
        configuration.icon
          .foregroundStyle(iconStyle)
      }
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
    iconPlacement: IconPlacement = .leading,
  ) -> Self {
    Self(
      textStyle: textStyle,
      iconStyle: iconStyle,
      lineStyle: lineStyle,
      fillStyle: fillStyle,
      iconPlacement: iconPlacement,
    )
  }

  static func badge(
    appearance: BadgeAppearance,
    iconPlacement: IconPlacement = .leading,
  ) -> Self {
    Self(
      textStyle: appearance.text,
      iconStyle: appearance.text,
      lineStyle: appearance.line,
      fillStyle: appearance.fill,
      iconPlacement: iconPlacement,
    )
  }
}

#if DEBUG
#Preview {
  WithColorSchemes(axis: .horizontal) {
    VStack {
      Label("Label", systemImage: "checkmark")
        .labelStyle(.badge)
        .controlSize(.mini)

      Label("Label", systemImage: "checkmark")
        .labelStyle(
          .badge(
            textStyle: .themeRed,
            iconStyle: .themeGreen,
            lineStyle: .themeRed,
            fillStyle: .themeYellow,
          )
        )
        .controlSize(.regular)

      Label("Label", systemImage: "checkmark")
        .labelStyle(
          .badge(
            appearance: .highlighted,
            iconPlacement: .trailing,
          )
        )
        .controlSize(.extraLarge)
        .imageScale(.small)
    }
    .padding()
  }
}
#endif
