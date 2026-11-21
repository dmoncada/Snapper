import SwiftUI

struct ToolbarTitle: ToolbarContent {
  enum Style {
    case large
    case inline
  }

  let title: LocalizedStringResource
  var style: Style = .large

  init(
    _ title: LocalizedStringResource,
    style: Style = .large,
  ) {
    self.title = title
    self.style = style
  }

  var body: some ToolbarContent {
    switch style {
    case .large:
      ToolbarItem(placement: .automatic) {
        Text(title)
          .frame(maxWidth: .infinity, alignment: .leading)
          .font(.zillaSlab(.largeTitle).bold())
          .foregroundStyle(.themePrimary)
      }
      .sharedBackgroundVisibility(.hidden)

    case .inline:
      ToolbarItem(placement: .principal) {
        Text(title)
          .font(.zillaSlab(.headline).bold())
          .foregroundStyle(.themePrimary)
      }
      .sharedBackgroundVisibility(.hidden)
    }
  }
}

extension View {
  func withToolbarTitle(
    _ title: LocalizedStringResource,
    style: ToolbarTitle.Style = .large,
  ) -> some View {
    toolbar {
      ToolbarTitle(title, style: style)
    }
    .navigationBarTitleDisplayMode(
      style == .inline
        ? .inline
        : .large
    )
  }
}

#if DEBUG
private struct TestToolbarTitle: View {
  let style: ToolbarTitle.Style

  var body: some View {
    NavigationStack {
      ScrollView {
        Text("Hello, world!")
      }
      .toolbar {
        ToolbarTitle("Hello", style: style)
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .cancel) {}
        }
      }
    }
  }
}

#Preview("Large") {
  TestToolbarTitle(style: .large)
}
#Preview("Principal") {
  TestToolbarTitle(style: .inline)
}
#endif
