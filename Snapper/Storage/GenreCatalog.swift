import Foundation
import SwiftData

@MainActor
struct GenreCatalog {
  private let context: ModelContext
  private var genresByName: [String: Genre]

  init(context: ModelContext) throws {
    self.context = context
    genresByName = [:]

    for genre in try context.fetch(FetchDescriptor<Genre>()) {
      genresByName[genre.name.lowercased()] = genre
    }
  }

  mutating func link(_ album: Album) {
    let names = album.genre.map(\.name)
    var resolved: [Genre] = []
    var seen: Set<String> = []

    for rawName in names {
      let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
      if name.isEmpty {
        continue
      }

      let key = name.lowercased()
      guard seen.insert(key).inserted else {
        continue
      }

      if let genre = genresByName[key] {
        resolved.append(genre)
      } else {
        let genre = Genre(name: name)

        context.insert(genre)

        genresByName[key] = genre
        resolved.append(genre)
      }
    }

    album.genre = resolved
  }
}
