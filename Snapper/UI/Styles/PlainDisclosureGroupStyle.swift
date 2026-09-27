import SwiftUI

struct PlainDisclosureGroupStyle: DisclosureGroupStyle {
  func makeBody(configuration: Configuration) -> some View {
    VStack(spacing: Spacing.md) {
      Button {
        withAnimation {
          configuration.isExpanded.toggle()
        }

      } label: {
        HStack {
          configuration.label
          Spacer()
          Image(systemName: "chevron.right")
            .rotationEffect(
              .degrees(configuration.isExpanded ? 90 : 0)
            )
        }
        .contentShape(.rect)
      }
      .buttonStyle(.plain)

      if configuration.isExpanded {
        configuration.content
      }
    }
  }
}

extension DisclosureGroupStyle where Self == PlainDisclosureGroupStyle {
  static var plain: Self { Self() }
}
