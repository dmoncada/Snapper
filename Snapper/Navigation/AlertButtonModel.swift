import SwiftUI

struct AlertButtonModel {
  let title: LocalizedStringResource
  let role: ButtonRole?
  let action: @MainActor () -> Void

  init(
    title: LocalizedStringResource,
    role: ButtonRole? = nil,
    action: @escaping @MainActor () -> Void = {},
  ) {
    self.title = title
    self.role = role
    self.action = action
  }
}

extension AlertButtonModel {
  static var cancel: Self {
    .init(title: "Cancel", role: .cancel)
  }

  static func cancel(title: LocalizedStringResource = "Cancel") -> Self {
    .init(title: title, role: .cancel)
  }
}
