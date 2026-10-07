import SwiftUI

struct PlainDisclosureGroupStyle: DisclosureGroupStyle {
  func makeBody(configuration: Configuration) -> some View {
    VStack {
      Button {
        withAnimation {
          configuration.isExpanded.toggle()
        }
      } label: {
        LabeledContent {
          Image(systemName: "chevron.right")
            .rotationEffect(
              .degrees(configuration.isExpanded ? 90 : 0)
            )
        } label: {
          configuration.label
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
