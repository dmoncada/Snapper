import SwiftData

enum SharedAlbumStore {
  static let groupId = "group.net.dmoncada.Snapper"

  static func makeContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(
      groupContainer: .identifier(groupId),
      cloudKitDatabase: .none,
    )

    return try ModelContainer(
      for: AlbumEntry.self,
      configurations: configuration,
    )
  }
}
