import SwiftUI

nonisolated enum IconPlacement {
  case leading
  case trailing
}

struct TitleAndIconBadgeToggleStyle<Style: LabelStyle>: ToggleStyle {
  @Environment(\.controlSize) private var controlSize

  let labelStyle: Style
  let appearance: BadgeAppearance

  func makeBody(configuration: Configuration) -> some View {
    Button {
      withAnimation(.snappy(duration: 0.25)) {
        configuration.isOn.toggle()
      }
    } label: {
      configuration.label
        .environment(\.isActive, configuration.isOn)
        .padding(Padding.md)
        .font(Typography.badge(for: controlSize))
        .foregroundStyle(appearance.text)
        .background {
          RoundedRectangle(cornerRadius: Radius.md)
            .fill(appearance.fill)
            .stroke(
              appearance.line,
              lineWidth: LineWidth.sm,
            )
        }
        .labelStyle(labelStyle)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
  }
}

struct ExpandLabelStyle: LabelStyle {
  @Environment(\.isActive) private var isOn: Bool

  let placement: IconPlacement

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: isOn ? Spacing.xs : 0) {
      if placement == .leading, isOn {
        icon(configuration)
      }

      configuration.title

      if placement == .trailing, isOn {
        icon(configuration)
      }
    }
  }

  private func icon(_ configuration: Configuration) -> some View {
    configuration.icon
      .symbolEffect(
        .bounce.up,
        options: .speed(2).nonRepeating,
        isActive: isOn,
      )
  }
}

struct SlideLabelStyle: LabelStyle {
  @Environment(\.isActive) private var isOn: Bool

  let placement: IconPlacement

  func makeBody(configuration: Configuration) -> some View {
    ShiftLabelLayout(
      placement: placement,
      spacing: Spacing.xs,
      isOn: isOn,
    ) {
      configuration.title

      configuration.icon
        .symbolEffect(
          .bounce.up,
          options: .speed(2).nonRepeating,
          isActive: isOn,
        )
        .opacity(isOn ? 1 : 0)
    }
  }
}

extension SlideLabelStyle {
  fileprivate struct ShiftLabelLayout: Layout {
    let placement: IconPlacement
    let spacing: CGFloat
    let isOn: Bool

    func sizeThatFits(
      proposal: ProposedViewSize,
      subviews: Subviews,
      cache: inout (),
    ) -> CGSize {
      let titleSize = subviews[0].sizeThatFits(.unspecified)
      let iconSize = subviews[1].sizeThatFits(.unspecified)

      return CGSize(
        width: titleSize.width + spacing + iconSize.width,
        height: max(titleSize.height, iconSize.height),
      )
    }

    func placeSubviews(
      in bounds: CGRect,
      proposal: ProposedViewSize,
      subviews: Subviews,
      cache: inout (),
    ) {
      let title = subviews[0]
      let icon = subviews[1]

      let titleSize = title.sizeThatFits(.unspecified)
      let iconSize = icon.sizeThatFits(.unspecified)

      let totalWidth = titleSize.width + spacing + iconSize.width

      let titleX: CGFloat
      let iconX: CGFloat

      if placement == .leading {
        iconX = bounds.minX + (bounds.width - totalWidth) / 2
        titleX = iconX + iconSize.width + spacing
      } else {
        titleX = bounds.minX + (bounds.width - totalWidth) / 2
        iconX = titleX + titleSize.width + spacing
      }

      let shift = (iconSize.width + spacing) / 2

      let titleOffset: CGFloat = {
        guard isOn else { return 0 }

        return placement == .leading ? shift : -shift
      }()

      title.place(
        at: CGPoint(
          x: bounds.midX + titleOffset,
          y: bounds.midY,
        ),
        anchor: .center,
        proposal: ProposedViewSize(titleSize),
      )

      icon.place(
        at: CGPoint(
          x: iconX + iconSize.width / 2,
          y: bounds.midY,
        ),
        anchor: .center,
        proposal: ProposedViewSize(iconSize),
      )
    }
  }
}

extension LabelStyle where Self == ExpandLabelStyle {
  static var expand: Self {
    Self(placement: .leading)
  }

  static func expand(_ placement: IconPlacement) -> Self {
    Self(placement: placement)
  }
}

extension LabelStyle where Self == SlideLabelStyle {
  static var slide: Self {
    Self(placement: .leading)
  }

  static func slide(_ placement: IconPlacement) -> Self {
    Self(placement: placement)
  }
}

struct TitleAndIconBadgeToggleModifier<S: LabelStyle>: ViewModifier {
  let labelStyle: S
  let appearance: BadgeAppearance

  func body(content: Content) -> some View {
    content
      .toggleStyle(
        TitleAndIconBadgeToggleStyle(
          labelStyle: labelStyle,
          appearance: appearance,
        )
      )
  }
}

extension View {
  func titleAndIconBadgeToggleStyle<S: LabelStyle>(
    labelStyle: S,
    appearance: BadgeAppearance = .default,
  ) -> some View {
    modifier(
      TitleAndIconBadgeToggleModifier(
        labelStyle: labelStyle,
        appearance: appearance,
      )
    )
  }
}

#if DEBUG
#Preview {
  @Previewable @State var isOn1 = false
  @Previewable @State var isOn2 = false
  @Previewable @State var isOn3 = false
  @Previewable @State var isOn4 = false

  WithColorSchemes(axis: .horizontal) {
    VStack(spacing: 12) {
      Toggle("Expand lead", systemImage: "arrow.left", isOn: $isOn1)
        .titleAndIconBadgeToggleStyle(labelStyle: .expand)
        .controlSize(.mini)

      Toggle("Expand trail", systemImage: "arrow.right", isOn: $isOn2)
        .titleAndIconBadgeToggleStyle(
          labelStyle: .expand(.trailing),
          appearance: isOn2
            ? .highlighted
            : .default,
        )
        .controlSize(.small)

      Toggle("Slide lead", systemImage: "arrow.left", isOn: $isOn3)
        .titleAndIconBadgeToggleStyle(labelStyle: .slide)
        .controlSize(.regular)

      Toggle("Slide trail", systemImage: "arrow.right", isOn: $isOn4)
        .titleAndIconBadgeToggleStyle(
          labelStyle: .slide(.trailing),
          appearance: isOn4
            ? .highlighted
            : .default,
        )
        .controlSize(.large)
    }
    .imageScale(.small)
    .padding()
  }
}
#endif
