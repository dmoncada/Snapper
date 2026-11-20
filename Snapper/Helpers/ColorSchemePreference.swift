import SwiftUI

enum ColorSchemePreference: String, CaseIterable, Identifiable {
  case system
  case light
  case dark

  var id: String {
    rawValue
  }

  var resource: LocalizedStringResource {
    switch self {
    case .system: .Settings.themeSystem
    case .light: .Settings.themeLight
    case .dark: .Settings.themeDark
    }
  }

  var colorScheme: ColorScheme? {
    switch self {
    case .system: nil
    case .light: .light
    case .dark: .dark
    }
  }
}
