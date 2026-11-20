import SwiftUI

enum ThemeContentUnavailableView {
  static func empty(
    _ title: LocalizedStringResource,
    description: LocalizedStringResource,
  ) -> some View {
    styled(
      title,
      systemImage: "tray.fill",
      description: description,
    )
  }

  static func search(
    _ title: LocalizedStringResource,
    description: LocalizedStringResource,
  ) -> some View {
    styled(
      title,
      systemImage: "magnifyingglass",
      description: description,
    )
  }

  static func search(text: String) -> some View {
    search(
      .searchNoResultsTitle(text: text),
      description: .searchNoResultsDesc,
    )
  }

  private static func styled(
    _ title: LocalizedStringResource,
    systemImage: String,
    description: LocalizedStringResource,
  ) -> some View {
    ContentUnavailableView {
      Label(title, systemImage: systemImage)
        .font(.zillaSlab(.title2).bold())
        .foregroundStyle(.primary)
    } description: {
      Text(description)
        .font(.gillSans(.title3))
        .foregroundStyle(.secondary)
    }
    .foregroundStyle(
      .themePrimary,
      .accent,
    )
  }
}
