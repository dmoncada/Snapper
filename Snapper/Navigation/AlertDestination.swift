import SwiftUI

struct AlertDestination: Identifiable {
  let id = UUID()
  let title: LocalizedStringResource
  let message: LocalizedStringResource
  let primary: AlertButtonModel
  let secondary: AlertButtonModel?

  init(
    title: LocalizedStringResource,
    message: LocalizedStringResource,
    primary: AlertButtonModel,
    secondary: AlertButtonModel? = nil,
  ) {
    self.title = title
    self.message = message
    self.primary = primary
    self.secondary = secondary
  }
}

extension AlertDestination {
  static func ok(
    _ message: LocalizedStringResource,
    title: LocalizedStringResource = "Notice",
    action: @escaping @MainActor () -> Void = {},
  ) -> Self {
    Self(
      title: title,
      message: message,
      primary: .init(title: "OK", action: action),
    )
  }
}

#if DEBUG
#Preview {
  @Previewable @State var alertItem: AlertDestination?

  VStack {
    Button("Show OK Alert") {
      alertItem = .ok(
        "The album was added to your history.",
        title: "Album created",
      )
    }
    .buttonStyle(.borderedProminent)
  }
  .withAlertDestination($alertItem)
}
#endif
