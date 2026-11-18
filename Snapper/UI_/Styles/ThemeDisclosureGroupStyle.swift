import SwiftUI

struct ThemeDisclosureGroupAppearance {
  let surface1: Color
  let surface2: Color
  let foregroundLabel: Color
  let foregroundContent: Color
  let border: Color

  static let `default` = Self(
    surface1: .accent,
    surface2: .clear,
    foregroundLabel: .themePrimary,
    foregroundContent: .themePrimary,
    border: .themeSeparator,
  )

  static let surface1 = Self(
    surface1: .themeSurface1,
    surface2: .clear,
    foregroundLabel: .themePrimaryActive,
    foregroundContent: .themePrimary,
    border: .themeSurface1,
  )
}

struct ThemeDisclosureGroupStyle: DisclosureGroupStyle {
  let appearance: ThemeDisclosureGroupAppearance

  func makeBody(configuration: Configuration) -> some View {
    VStack(spacing: 0) {
      Button {
        withAnimation(.snappy(duration: 0.375)) {
          configuration.isExpanded.toggle()
        }
      } label: {
        HStack {
          configuration.label
          Spacer()
          Image(systemName: "chevron.right")
            .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
            .imageScale(.small)
        }
        .padding(12)
        .frame(
          maxWidth: .infinity,
          alignment: .leading,
        )
        .foregroundStyle(appearance.foregroundLabel)
        .background(appearance.surface1)
        .contentShape(.rect)
      }
      .buttonStyle(.plain)

      if configuration.isExpanded {
        configuration.content
          // .padding(12)
          .frame(
            maxWidth: .infinity,
            alignment: .leading,
          )
          .foregroundStyle(appearance.foregroundContent)
          .background(appearance.surface2)
      }
    }
    .clipShape(.rect(cornerRadius: Radius.sm))
    .overlay {
      RoundedRectangle(cornerRadius: Radius.sm)
        .stroke(
          appearance.border,
          lineWidth: LineWidth.md,
        )
    }
    .frame(maxWidth: .infinity)
  }
}

extension DisclosureGroupStyle where Self == ThemeDisclosureGroupStyle {
  static var theme: Self {
    Self(appearance: .default)
  }

  static func theme(_ appearance: ThemeDisclosureGroupAppearance = .default) -> Self {
    Self(appearance: appearance)
  }
}
