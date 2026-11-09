import Foundation
import SwiftData
import SwiftUI

enum Application {
  static var isTest: Bool {
    #if DEBUG
    ProcessInfo.processInfo.arguments.contains("-screenshot-fixtures")
    #else
    false
    #endif
  }
}

protocol DateTimeProviding {
  var now: Date { get }
}

struct StubDateTimeProvider: DateTimeProviding {
  init(_ container: ModelContainer? = nil) {
    self.container = container ?? (try? SampleDataStore.makeContainer())
  }

  private let container: ModelContainer?

  var now: Date {
    guard
      let context = container?.mainContext,
      let albums = try? context.fetch(FetchDescriptor<Album>()),
      let latest = albums.map(\.selectedAt).max()
    else { return .now }

    return latest.addingTimeInterval(90)
  }
}

struct LiveDateTimeProvider: DateTimeProviding {
  var now: Date { .now }
}

extension DateTimeProviding where Self == StubDateTimeProvider {
  static var stub: Self { Self() }
  static func stub(_ container: ModelContainer) -> Self { Self(container) }
}

extension DateTimeProviding where Self == LiveDateTimeProvider {
  static var live: Self { Self() }
}
