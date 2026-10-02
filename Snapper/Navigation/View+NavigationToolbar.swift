import SwiftUI

struct NavigationToolbarModifier: ViewModifier {
  let title: String
  var onClose: () -> Void = {}

  func body(content: Content) -> some View {
    content
      .navigationTitle(title)
      #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(role: .close) {
            onClose()
          }
        }
      }
  }
}

extension View {
  func navigationToolbar(title: String, onClose: @escaping () -> Void = {}) -> some View {
    modifier(NavigationToolbarModifier(title: title, onClose: onClose))
  }
}

#if DEBUG
#Preview {
  NavigationStack {
    Text("Hello, world!")
      .navigationToolbar(title: "Title")
  }
}
#endif
