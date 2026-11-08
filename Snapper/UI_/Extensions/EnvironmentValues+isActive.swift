import SwiftUI

private struct IsActiveKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  var isActive: Bool {
    get { self[IsActiveKey.self] }
    set { self[IsActiveKey.self] = newValue }
  }
}
