import SwiftUI

extension Divider {
  func withThemeDividerStyle() -> some View {
    self
      .frame(height: 1)
      .overlay(Color.themeSeparator)
  }
}
