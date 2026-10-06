import Foundation
import SwiftData

@MainActor
enum SampleAlbumStore {
  static func makeContainer(limit: Int? = nil) throws -> ModelContainer {
    let container = try ModelContainer(
      for: AlbumEntry.self,
      configurations: .init(isStoredInMemoryOnly: true),
    )

    guard let url = Bundle.main.url(forResource: "albums", withExtension: "json") else {
      throw SampleAlbumStoreError.missingFixture
    }

    let data = try Data(contentsOf: url)
    let albums = try JSONDecoder().decode([SampleAlbum].self, from: data)
    let selectedAlbums = limit.map { Array(albums.prefix($0)) } ?? albums

    for album in selectedAlbums {
      let candidate = AlbumCandidate(
        id: album.discogsReleaseId,
        artist: album.artist,
        title: album.title,
        year: album.year,
        formats: album.formats,
        labels: album.labels,
        country: album.country,
        thumbnailUrl: album.thumbnailUrlString.flatMap(URL.init(string:)),
        coverImageUrl: album.coverImageUrlString.flatMap(URL.init(string:)),
        discogsUrl: album.discogsUrlString.flatMap(URL.init(string:)),
      )

      container.mainContext.insert(AlbumEntry(candidate: candidate))
    }

    try container.mainContext.save()
    return container
  }
}

private enum SampleAlbumStoreError: Error {
  case missingFixture
}

private struct SampleAlbum: Decodable {
  let artist: String
  let country: String?
  let coverImageUrlString: String?
  let discogsReleaseId: Int
  let discogsUrlString: String?
  let formats: [String]
  let labels: [String]
  let thumbnailUrlString: String?
  let title: String
  let year: Int?
}
