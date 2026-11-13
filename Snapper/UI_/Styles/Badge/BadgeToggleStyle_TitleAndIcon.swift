import SwiftUI

nonisolated enum IconPlacement {
  case leading
  case trailing
}

enum LabelBehavior {
  case expand(IconPlacement)
  case slide(IconPlacement)

  static var expand: Self { .expand(.leading) }
  static var slide: Self { .slide(.leading) }
}

struct TitleAndIconBadgeToggleStyle: ToggleStyle {
  @Environment(\.controlSize) private var controlSize

  let labelStyle: LabelBehavior
  let appearance: BadgeAppearance

  func makeBody(configuration: Configuration) -> some View {
    Button {
      withAnimation(.snappy(duration: 0.25)) {
        configuration.isOn.toggle()
      }
    } label: {
      styled(configuration.label)
        .environment(\.isActive, configuration.isOn)
        .padding(Padding.md)
        .font(Typography.badge.for(controlSize))
        .foregroundStyle(appearance.text)
        .background {
          RoundedRectangle(cornerRadius: Radius.md)
            .fill(appearance.fill)
            .stroke(
              appearance.line,
              lineWidth: LineWidth.sm,
            )
        }
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func styled(_ label: Configuration.Label) -> some View {
    switch labelStyle {
    case .expand(let placement):
      label
        .labelStyle(ExpandLabelStyle(placement: placement))

    case .slide(let placement):
      label
        .labelStyle(SlideLabelStyle(placement: placement))
    }
  }
}

private struct ExpandLabelStyle: LabelStyle {
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

private struct SlideLabelStyle: LabelStyle {
  @Environment(\.isActive) private var isOn: Bool

  let placement: IconPlacement

  func makeBody(configuration: Configuration) -> some View {
    SlideLabelLayout(
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
  private struct SlideLabelLayout: Layout {
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

extension ToggleStyle where Self == TitleAndIconBadgeToggleStyle {
  static var titleAndIconBadge: Self {
    Self(
      labelStyle: .expand(.leading),
      appearance: .default,
    )
  }

  static func titleAndIconBadge(
    labelStyle: LabelBehavior,
    appearance: BadgeAppearance = .default,
  ) -> Self {
    Self(
      labelStyle: labelStyle,
      appearance: appearance,
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
        .toggleStyle(.titleAndIconBadge)
        .controlSize(.mini)

      Toggle("Expand trail", systemImage: "arrow.right", isOn: $isOn2)
        .toggleStyle(
          .titleAndIconBadge(
            labelStyle: .expand(.trailing),
            appearance: isOn2
              ? .highlighted
              : .default,
          )
        )
        .controlSize(.small)

      Toggle("Slide lead", systemImage: "arrow.left", isOn: $isOn3)
        .toggleStyle(.titleAndIconBadge(labelStyle: .slide))
        .controlSize(.regular)

      Toggle("Slide trail", systemImage: "arrow.right", isOn: $isOn4)
        .toggleStyle(
          .titleAndIconBadge(
            labelStyle: .slide(.trailing),
            appearance: isOn4
              ? .highlighted
              : .default,
          )
        )
        .controlSize(.large)
    }
    .imageScale(.small)
    .padding()
  }
}
#endif
