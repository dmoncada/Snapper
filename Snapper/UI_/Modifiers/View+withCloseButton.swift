import SwiftUI

struct SheetCloseButton: ViewModifier {
  @Environment(\.dismiss) private var dismiss

  let action: (() -> Void)?

  func body(content: Content) -> some View {
    content
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .cancel) {
            dismiss()
            action?()
          }
        }
      }
  }
}

extension View {
  func withCloseButton(
    action: (() -> Void)? = nil
  ) -> some View {
    modifier(SheetCloseButton(action: action))
  }
}
