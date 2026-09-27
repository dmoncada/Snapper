import SwiftUI

enum AppStorageKeys {
  static let colorScheme = "colorSchemePreference"
}

extension String {
  static var storageKeys: AppStorageKeys.Type { AppStorageKeys.self }
}
