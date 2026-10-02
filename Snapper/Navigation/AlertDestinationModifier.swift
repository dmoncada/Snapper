import SwiftUI

struct AlertDestinationModifier: ViewModifier {
  let item: Binding<AlertDestination?>

  func body(content: Content) -> some View {
    content
      .alert(item.wrappedValue?.title ?? "", item: item) { destination in
        if let secondary = destination.secondary {
          Button(
            secondary.title,
            role: secondary.role,
            action: secondary.action,
          )
        }

        Button(
          destination.primary.title,
          role: destination.primary.role,
          action: destination.primary.action,
        )
      } message: { destination in
        Text(destination.message)
      }
  }
}

extension View {
  func withAlertDestination(_ item: Binding<AlertDestination?>) -> some View {
    modifier(AlertDestinationModifier(item: item))
  }
}

#if DEBUG
#Preview {
  @Previewable @State var alertItem: AlertDestination?

  VStack(spacing: 24) {
    Button("Acknowledge") {
      alertItem = AlertDestination(
        title: "Album created",
        message: "The album was added to your history.",
        primary: .init(title: "OK"),
      )
    }
    .buttonStyle(.borderedProminent)

    Button("Confirm") {
      alertItem = AlertDestination(
        title: "Could not create album",
        message: "Please try again.",
        primary: .init(title: "Retry") { print("Retry") },
        secondary: .cancel,
      )
    }
    .buttonStyle(.borderedProminent)

    Button("Confirm delete") {
      alertItem = AlertDestination(
        title: "Delete album?",
        message: "The album will be removed from your history.",
        primary: .init(title: "Delete", role: .destructive) { print("Delete") },
        secondary: .cancel,
      )
    }
    .buttonStyle(.borderedProminent)
  }
  .withAlertDestination($alertItem)
}
#endif
