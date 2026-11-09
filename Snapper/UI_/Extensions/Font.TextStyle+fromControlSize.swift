import SwiftUI

extension Font.TextStyle {
  static func fromControlSize(_ controlSize: ControlSize) -> Font.TextStyle {
    switch controlSize {
    case .mini: .caption2
    case .small: .caption
    case .regular: .body
    case .large: .title3
    case .extraLarge: .title2
    @unknown default: .body
    }
  }
}
