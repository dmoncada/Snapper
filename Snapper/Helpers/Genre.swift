import SwiftData

@Model
final class Genre {
  var name: String
  var albums: [Album] = []

  init(name: String) {
    self.name = name
  }
}
