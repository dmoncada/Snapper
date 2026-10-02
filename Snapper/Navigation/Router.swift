import Observation
import SwiftUI

@MainActor
@Observable
final class Router {
  var path = NavigationPath()
  var sheetItem: SheetDestination? = nil
  var alertItem: AlertDestination? = nil

  func showSheet(destination: SheetDestination) {
    sheetItem = destination
  }

  func hideSheet() {
    sheetItem = nil
  }

  func navigate(to destination: any Hashable) {
    path.append(destination)
  }

  func navigateBack() {
    path.removeLast()
  }

  func navigateToRoot() {
    path.removeLast(path.count)
  }
}
