import Foundation
import SwiftData

@MainActor
enum SampleDataStore {
  static func makeContainer(
    named name: String = "albums",
    limit: Int = 10,
  ) throws -> ModelContainer {
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

    var file = try SampleDataLoader.importData(named: name)

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

      if file.albums[index].thumbnailUrl?.scheme != "assets" {
        file.albums[index].thumbnailUrl = artworkUrl
      }
      if file.albums[index].coverImageUrl?.scheme != "assets" {
        file.albums[index].coverImageUrl = artworkUrl
      }
    }

    try SampleDataLoader.insert(
      file,
      into: container.mainContext,
    )

    return container
  }

  static func makeEmpty() throws -> ModelContainer {
    try makeContainer(limit: 0)
  }
}
