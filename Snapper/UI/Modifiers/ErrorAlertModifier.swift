import SwiftUI

struct ErrorAlertModifier: ViewModifier {
  @Binding var error: Error?

  func body(content: Content) -> some View {
    content
      .alert(
        "Error",
        isPresented: .isPresented(for: $error),
      ) {
        Button("Ok", role: .cancel) {}
      } message: {
        Text(error?.localizedDescription ?? "")
      }
  }
}

extension View {
  func errorAlert(for error: Binding<Error?>) -> some View {
    modifier(ErrorAlertModifier(error: error))
  }
}

#if DEBUG
#Preview {
  @Previewable @State var error: Error?

  Button("Show alert") {
    error = URLError(.badURL)
  }
  .errorAlert(for: $error)
}
#endif
