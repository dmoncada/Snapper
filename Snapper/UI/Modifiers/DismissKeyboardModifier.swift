import SwiftUI

extension View {
  func dismissKeyboard() {
    UIApplication.shared.resignCurrentResponder()
  }

  func dismissKeyboardOnTap() -> some View {
    modifier(DismissKeyboardModifier())
  }
}

struct DismissKeyboardModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .gesture(
        TapGesture()
          .onEnded {
            UIApplication.shared.resignCurrentResponder()
          }
      )
  }
}

extension UIApplication {
  func resignCurrentResponder() {
    sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil,
      from: nil,
      for: nil,
    )
  }
}
