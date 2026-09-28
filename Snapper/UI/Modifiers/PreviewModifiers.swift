import SwiftData
import SwiftUI

struct NoData: PreviewModifier {
  static func makeSharedContext() throws -> ModelContainer {
    let container = try ModelContainer(for: AlbumEntry.self)
    try container.erase()
    return container
  }

  func body(content: Content, context: ModelContainer) -> some View {
    content
      .modelContainer(context)
  }
}

struct SampleData: PreviewModifier {
  static func makeSharedContext() throws -> ModelContainer {
    let container = try ModelContainer(
      for: AlbumEntry.self, configurations: .init(isStoredInMemoryOnly: true))

    guard let url = Bundle.main.url(forResource: "albums", withExtension: "json") else {
      fatalError("Unable to find sample data file in bundle.")
    }

    guard let albums = try? loadAlbums(from: url) else {
      fatalError("Unable to parse sample data file.")
    }

    for album in albums {
      container.mainContext.insert(AlbumEntry(candidate: album, selectedAt: .now))
    }

    try container.mainContext.save()

    return container
  }

  private static func loadAlbums(from url: URL) throws -> [AlbumCandidate] {
    let data = try Data(contentsOf: url)
    let rawAlbums = try JSONDecoder().decode([AlbumCandidateDto].self, from: data)
    return rawAlbums.map { .init($0) }
  }

  func body(content: Content, context: ModelContainer) -> some View {
    content
      .modelContainer(context)
  }
}

extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor static var withoutData: Self = .modifier(NoData())
}
extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor static var withSampleData: Self = .modifier(SampleData())
}

private struct AlbumCandidateDto: Decodable {
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

extension AlbumCandidate {
  fileprivate init(_ dto: AlbumCandidateDto) {
    id = dto.discogsReleaseId
    artist = dto.artist
    title = dto.title
    year = dto.year
    formats = dto.formats
    labels = dto.labels
    country = dto.country
    thumbnailUrl = dto.thumbnailUrlString.flatMap(URL.init(string:))
    coverImageUrl = dto.coverImageUrlString.flatMap(URL.init(string:))
    discogsUrl = dto.discogsUrlString.flatMap(URL.init(string:))
  }
}
