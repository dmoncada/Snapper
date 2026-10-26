import Foundation
import SwiftData

enum SampleDataLoader {
  static let currentVersion = 1

  private static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return encoder
  }()

  private static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }()

  static func encode(_ file: AlbumFixtureFile) throws -> Data {
    try encoder.encode(file)
  }

  static func decode(_ data: Data) throws -> AlbumFixtureFile {
    let file = try decoder.decode(AlbumFixtureFile.self, from: data)

    guard file.version == currentVersion else {
      throw FixtureError.unsupportedVersion(file.version)
    }

    return file
  }

  static func importData(
    named name: String = "albums",
    bundle: Bundle = .main,
  ) throws -> AlbumFixtureFile {
    guard
      let url = bundle.url(
        forResource: name,
        withExtension: "json",
      )
    else {
      throw FixtureError.fileNotFound(name)
    }

    return try decode(Data(contentsOf: url))
  }

  @MainActor
  static func exportData(from context: ModelContext) throws -> Data {
    let descriptor = FetchDescriptor<Album>(
      sortBy: [SortDescriptor(\.selectedAt)]
    )

    let albums = try context.fetch(descriptor)

    let file = AlbumFixtureFile(
      version: currentVersion,
      albums: albums.map(AlbumFixture.init),
    )

    return try encode(file)
  }

  @MainActor
  static func insert(
    _ file: AlbumFixtureFile,
    into context: ModelContext,
    limit: Int? = nil,
    replacingExisting: Bool = false,
  ) throws {
    if replacingExisting {
      try context.delete(model: Album.self)
      // Album.tracks uses a cascade delete rule.
    }

    let albums =
      limit.map { Array(file.albums.prefix(max(0, $0))) }
      ?? file.albums

    for fixture in albums {
      context.insert(fixture.makeModel())
    }

    try context.save()
  }
}

enum FixtureError: LocalizedError {
  case unsupportedVersion(Int)
  case fileNotFound(String)

  var errorDescription: String {
    switch self {
    case .unsupportedVersion(let version):
      "Unsupported fixture version: \(version)"

    case .fileNotFound(let name):
      "Could not find \(name).json in the app bundle."
    }
  }
}
