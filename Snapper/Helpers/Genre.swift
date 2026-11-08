import Foundation

enum Genre: String, CaseIterable, Hashable, Identifiable {
  case blues = "Blues"
  case electronic = "Electronic"
  case hipHop = "Hip Hop"
  case jazz = "Jazz"
  case latin = "Latin"
  case pop = "Pop"
  case rock = "Rock"

  init?(value: String) {
    self.init(rawValue: value.trimmingCharacters(in: .whitespacesAndNewlines))
  }

  var id: Self { self }

  var title: String { rawValue.capitalized }
}
