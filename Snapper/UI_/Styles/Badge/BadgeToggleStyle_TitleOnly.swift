import SwiftUI

struct TitleOnlyBadgeToggleStyle: ToggleStyle {
  private func textStyle(_ configuration: Configuration) -> some ShapeStyle {
    configuration.isOn
      ? AnyShapeStyle(.themePrimary.inverted())
      : AnyShapeStyle(.themePrimary)
  }

  private func lineStyle(_ configuration: Configuration) -> some ShapeStyle {
    configuration.isOn
      ? .accent
      : .themeSeparator
  }

  private func fillStyle(_ configuration: Configuration) -> some ShapeStyle {
    configuration.isOn
      ? .accent
      : .clear
  }

  func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      configuration.label
        .badgeStyle(
          textStyle: textStyle(configuration),
          lineStyle: lineStyle(configuration),
          fillStyle: fillStyle(configuration),
        )
        .animation(nil, value: configuration.isOn)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
  }
}

extension ToggleStyle where Self == TitleOnlyBadgeToggleStyle {
  static var titleOnlyBadge: Self {
    Self()
  }
}

#if DEBUG
#Preview {
  @Previewable @State var isOn = false

  WithColorSchemes {
    VStack(spacing: 12) {
      Toggle("Title Only", isOn: $isOn)
        .toggleStyle(.titleOnlyBadge)
        .controlSize(.small)
    }
    .padding()
  }
}
#endif
