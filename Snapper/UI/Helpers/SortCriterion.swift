enum SortCriterion: String, CaseIterable, Identifiable {
  case dateFound, songTitle, artistName

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .dateFound: "Date Found"
    case .songTitle: "Song Title"
    case .artistName: "Artist Name"
    }
  }
}

enum SortOrder: String, CaseIterable, Identifiable {
  case newestFirst, oldestFirst
  case ascending, descending

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
    case .songTitle, .artistName: .ascending
    }
  }

  var orders: [SortOrder] {
    switch self {
    case .dateFound: [.newestFirst, .oldestFirst]
    case .songTitle, .artistName: [.ascending, .descending]
    }
  }
}
