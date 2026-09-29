import SwiftUI

enum AppStorageKeys {
  static let colorScheme = "colorSchemePreference"
  static let sortConfiguration = "sortConfiguration"
}

extension String {
  static var storageKeys: AppStorageKeys.Type { AppStorageKeys.self }
}
