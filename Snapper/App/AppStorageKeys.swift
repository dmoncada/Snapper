import SwiftUI

enum AppStorageKeys {
  static let firstLaunch = "firstLaunch"
  static let colorScheme = "colorSchemePreference"
  static let openFirstResult = "openFirstResult"
  static let sortConfiguration = "sortConfiguration"
}

extension String {
  static var storageKeys: AppStorageKeys.Type { AppStorageKeys.self }
}
