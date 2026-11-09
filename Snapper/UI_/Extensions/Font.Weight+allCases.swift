import SwiftUI

extension Font.Weight: @retroactive CaseIterable {
  public static var allCases: [Font.Weight] {
    [
      .ultraLight,
      .thin,
      .light,
      .regular,
      .medium,
      .semibold,
      .bold,
      .heavy,
      .black,
    ]
  }
}

extension Font.Weight {
  var name: String {
    switch self {
    case .ultraLight: "Ultra Light"
    case .thin: "Thin"
    case .light: "Light"
    case .regular: "Regular"
    case .medium: "Medium"
    case .semibold: "Semi Bold"
    case .bold: "Bold"
    case .heavy: "Heavy"
    case .black: "Black"
    default: "Unknown"
    }
  }
}
