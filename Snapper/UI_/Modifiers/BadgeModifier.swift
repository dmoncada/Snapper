import SwiftUI

struct BadgeModifier: ViewModifier {
  @Environment(\.controlSize) private var controlSize

  func body(content: Content) -> some View {
    content
      .padding(Padding.md)
      .font(Typography.badge(for: controlSize))
      .foregroundStyle(.primary)
      .background {
        RoundedRectangle(cornerRadius: Radius.md)
          .fill(.secondary)
          .stroke(.tertiary, lineWidth: LineWidth.sm)
      }
  }
}

extension View {
  func badgeStyle<
    TextStyle: ShapeStyle,
    LineStyle: ShapeStyle,
    FillStyle: ShapeStyle,
  >(
    textStyle: TextStyle = .themePrimary,
    lineStyle: LineStyle = .themeSeparator,
    fillStyle: FillStyle = .clear,
  ) -> some View {
    modifier(BadgeModifier())
      .foregroundStyle(
        textStyle,
        fillStyle,
        lineStyle,
      )
  }

  func badgeStyle(appearance: BadgeAppearance) -> some View {
    modifier(BadgeModifier())
      .foregroundStyle(
        appearance.text,
        appearance.fill,
        appearance.line,
      )
  }
}

#if DEBUG
#Preview {
  WithColorSchemes(axis: .horizontal) {
    VStack {
      Text("Mini")
        .badgeStyle()
        .controlSize(.mini)

      Text("Regular")
        .badgeStyle(
          textStyle: .themeRed,
          lineStyle: .themeRed,
        )

      Text("Extra Large")
        .badgeStyle(appearance: .highlighted)
        .controlSize(.extraLarge)
    }
    .padding()
  }
}
#endif
