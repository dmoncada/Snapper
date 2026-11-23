import SwiftUI

@MainActor
@Observable
final class AppNavigation {
  var screen: AppScreen = .search

  var deepLink: AppDeepLink?

  func open(_ deepLink: AppDeepLink) {
    switch deepLink {
    case .camera:
      self.screen = .search
      self.deepLink = deepLink
    }
  }
}

extension EnvironmentValues {
  @Entry var navigation: AppNavigation? = nil
}
