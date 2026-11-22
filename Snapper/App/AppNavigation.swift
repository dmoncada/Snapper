import SwiftUI

@MainActor
@Observable
final class AppNavigation {
  var screen: AppScreen = .search
}

extension EnvironmentValues {
  @Entry var navigation: AppNavigation? = nil
}
