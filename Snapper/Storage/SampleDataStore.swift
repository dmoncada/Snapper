import Foundation
import SwiftData

@MainActor
enum SampleDataStore {
  static func makeContainer(limit: Int = 10) throws -> ModelContainer {
    let configuration = ModelConfiguration(
      isStoredInMemoryOnly: true
    )

    let container = try ModelContainer(
      for: SnapperStore.schema,
      configurations: [configuration],
    )

    if limit <= 0 {
      return container
    }

    var file = try SampleDataLoader.importData()

    file.albums = Array(
      file
        .albums
        .sorted { $0.selectedAt > $1.selectedAt }
        .prefix(min(limit, 10))
    )

    for index in file.albums.indices {
      let discogsId = file.albums[index].discogsId
      let artworkUrl = URL(string: "assets:///Album-\(discogsId)")
      guard let artworkUrl else { throw URLError(.badURL) }
      file.albums[index].thumbnailUrl = artworkUrl
      file.albums[index].coverImageUrl = artworkUrl
    }

    try SampleDataLoader.insert(
      file,
      into: container.mainContext,
    )

    return container
  }
}
