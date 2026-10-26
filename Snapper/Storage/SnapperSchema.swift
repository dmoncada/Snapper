import SwiftData

enum SnapperSchema {
  static var models: [any PersistentModel.Type] {
    [
      Album.self,
      Track.self,
    ]
  }
}
