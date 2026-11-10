import SwiftUI

struct Pressable: ViewModifier {
  let isPressed: Bool
  let scale: CGFloat

  init(isPressed: Bool, scale: CGFloat = 0.975) {
    self.isPressed = isPressed
    self.scale = scale
  }

  func body(content: Content) -> some View {
    content
      .scaleEffect(isPressed ? scale : 1)
      .animation(.easeOut(duration: 0.1), value: isPressed)
  }
}

struct PressedScaleButtonStyle: ButtonStyle {
  let scale: CGFloat

  init(scale: CGFloat = 0.975) {
    self.scale = scale
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .modifier(
        Pressable(
          isPressed: configuration.isPressed,
          scale: scale,
        )
      )
  }
}

extension ButtonStyle where Self == PressedScaleButtonStyle {
  static var pressedScale: Self { Self() }

  static func pressedScale(_ scale: CGFloat) -> Self {
    Self(scale: scale)
  }
}

struct ThemeButonLabelStyle: LabelStyle {
  @Environment(\.colorScheme) private var scheme

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: Spacing.xs) {
      configuration.icon
      configuration.title
    }
    .padding(.vertical, Padding.xl)
    .frame(maxWidth: .infinity)
    .font(Typography.buttonBody)
    .imageScale(.small)
    .background(
      scheme == .dark
        ? .themeSeafoam
        : .themeGray
    )
    .contentShape(.rect)
    .roundedOutline(
      lineStyle: .clear
    )
  }
}

struct ThemeButtonStyle: ButtonStyle {
  let scale: CGFloat

  init(scale: CGFloat = 0.975) {
    self.scale = scale
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      // .textCase(.uppercase)
      .labelStyle(ThemeButonLabelStyle())
      .modifier(
        Pressable(
          isPressed: configuration.isPressed,
          scale: scale,
        )
      )
  }
}

extension ButtonStyle where Self == ThemeButtonStyle {
  static var theme: Self { Self() }
}

#if DEBUG
#Preview {
  WithColorSchemes {
    HStack {
      Button("Pick", systemImage: "photo") {}
      Button("Snap", systemImage: "camera") {}
    }
    .buttonStyle(.theme)
    .padding()
  }
}
#endif
