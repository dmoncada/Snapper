import Foundation
import Observation

enum SortCriterion: String, CaseIterable, Codable, Identifiable {
  case dateFound
  case albumTitle
  case artistName

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .dateFound: "Date Found"
    case .albumTitle: "Album Title"
    case .artistName: "Artist Name"
    }
  }
}

enum SortOrder: String, CaseIterable, Codable, Identifiable {
  case newestFirst
  case oldestFirst
  case ascending
  case descending

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .newestFirst: "Newest First"
    case .oldestFirst: "Oldest First"
    case .ascending: "Ascending"
    case .descending: "Descending"
    }
  }
}

extension SortCriterion {
  var defaultOrder: SortOrder {
    switch self {
    case .dateFound: .newestFirst
    case .albumTitle, .artistName: .ascending
    }
  }

  var orders: [SortOrder] {
    switch self {
    case .dateFound: [.newestFirst, .oldestFirst]
    case .albumTitle, .artistName: [.ascending, .descending]
    }
  }

  func checkOrdered(
    _ lhs: AlbumEntry,
    _ rhs: AlbumEntry,
    order: SortOrder,
  ) -> Bool {
    switch self {
    case .albumTitle:
      compare(lhs.title, rhs.title, order: order)

    case .artistName:
      compare(lhs.artist, rhs.artist, order: order)

    case .dateFound:
      compare(lhs.selectedAt, rhs.selectedAt, order: order)
    }
  }

  fileprivate func compare<T: Comparable>(
    _ lhs: T,
    _ rhs: T,
    order: SortOrder,
  ) -> Bool {
    switch order {
    case .ascending, .oldestFirst: lhs < rhs
    case .descending, .newestFirst: lhs > rhs
    }
  }
}

struct SortConfiguration: Codable, Equatable {
  var criterion: SortCriterion
  var orders: [SortCriterion: SortOrder]

  static let `default` = Self(
    criterion: .dateFound,
    orders: [
      .dateFound: .newestFirst,
      .albumTitle: .ascending,
      .artistName: .ascending,
    ],
  )

  func getOrder(for criterion: SortCriterion) -> SortOrder {
    orders[criterion] ?? criterion.defaultOrder
  }

  mutating func setOrder(_ order: SortOrder, for criterion: SortCriterion) {
    orders[criterion] = order
  }
}

@Observable
class SortModel {
  var configuration: SortConfiguration {
    didSet {
      save()
    }
  }

  private let encoder = JSONEncoder()

  init() {
    configuration = Self.load()
  }

  var criterion: SortCriterion {
    get { configuration.criterion }
    set { configuration.criterion = newValue }
  }

  func getOrder(for criterion: SortCriterion) -> SortOrder {
    configuration.getOrder(for: criterion)
  }

  func setOrder(_ order: SortOrder, for criterion: SortCriterion) {
    configuration.setOrder(order, for: criterion)
  }

  private func save() {
    guard let data = try? encoder.encode(configuration)
    else { return }

    UserDefaults.standard.set(data, forKey: .storageKeys.sortConfiguration)
  }

  private static func load() -> SortConfiguration {
    guard
      let data = UserDefaults.standard.data(forKey: .storageKeys.sortConfiguration),
      let configuration = try? JSONDecoder().decode(SortConfiguration.self, from: data)
    else { return .default }

    return configuration
  }
}
