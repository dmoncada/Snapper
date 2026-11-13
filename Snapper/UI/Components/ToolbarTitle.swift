import SwiftUI

struct ToolbarTitle: ToolbarContent {
  let title: LocalizedStringKey

  init(_ title: LocalizedStringKey) {
    self.title = title
  }

  var body: some ToolbarContent {
    ToolbarItem(placement: .automatic) {
      Text(title)
        .frame(
          maxWidth: .infinity,
          alignment: .leading,
        )
        .font(.zillaSlab(.largeTitle).bold())
        .foregroundStyle(.primary)
    }
    .sharedBackgroundVisibility(.hidden)
  }
}

#if DEBUG
#Preview {
  NavigationStack {
    ScrollView {
      Text("Hello, world!")
    }
    .toolbar {
      ToolbarTitle("Hello")
      ToolbarItem(placement: .topBarTrailing) {
        Button(role: .cancel) {}
      }
    }
    .toolbarBackground(.thinMaterial, for: .navigationBar)
    .toolbarBackgroundVisibility(.visible, for: .navigationBar)
  }
}
#endif
