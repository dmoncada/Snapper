import Foundation
import SwiftData
import SwiftUI

enum Application {
  static var isTest: Bool {
    #if DEBUG
    ProcessInfo.processInfo.arguments.contains(AppLaunchConfiguration.uiTest)
    #else
    false
    #endif
  }
}

enum AppLaunchConfiguration {
  static let uiTest = "-ui-test"
}
