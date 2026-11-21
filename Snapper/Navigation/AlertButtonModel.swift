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
    .init(title: .toolsCancel, role: .cancel)
  }

  static func cancel(title: LocalizedStringResource = .toolsCancel) -> Self {
    .init(title: title, role: .cancel)
  }

  static var confirm: Self {
    .init(title: .toolsConfirm, role: .confirm)
  }

  static func confirm(title: LocalizedStringResource = .toolsConfirm) -> Self {
    .init(title: title, role: .confirm)
  }

  static func delete(
    title: LocalizedStringResource = .toolsDelete,
    action: @escaping @MainActor () -> Void = {},
  ) -> Self {
    .init(title: title, role: .destructive, action: action)
  }
}
