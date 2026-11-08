import SwiftData

enum SnapperSchema {
  static var models: [any PersistentModel.Type] {
    [
      Album.self,
      Genre.self,
      Track.self,
    ]
  }
}
