import SwiftUI

extension Binding {
  static func isPresented<T>(for value: Binding<T?>) -> Binding<Bool> {
    Binding<Bool>(
      get: { value.wrappedValue != nil },
      set: { if !$0 { value.wrappedValue = nil } },
    )
  }
}
