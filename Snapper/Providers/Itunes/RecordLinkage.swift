import Foundation

nonisolated enum RecordLinkage {
  static func bestCollection(
    from results: [ItunesSearchResult],
    for candidate: AlbumCandidate
  ) -> ItunesSearchResult? {
    let scoredResults = results.compactMap { result -> (ItunesSearchResult, Double)? in
      guard
        let artist = result.artistName,
        let title = result.collectionName,
        let collectionId = result.collectionId,
        collectionId > 0,
        isCompatibleEdition(candidate.title, title)
      else { return nil }

      let artistScore = jaroWinkler(normalize(candidate.artist), normalize(artist))
      let titleScore = jaroWinkler(normalize(candidate.title), normalize(title))
      guard artistScore >= 0.92, titleScore >= 0.90 else { return nil }

      return (result, (artistScore * 0.4) + (titleScore * 0.6))
    }
    .sorted { $0.1 > $1.1 }

    guard let best = scoredResults.first, best.1 >= 0.93 else { return nil }
    guard scoredResults.count == 1 || best.1 - scoredResults[1].1 >= 0.05 else { return nil }
    return best.0
  }

  static func bestArtist(
    from results: [ItunesSearchResult],
    named artist: String
  ) -> ItunesSearchResult? {
    let normalizedArtist = normalize(artist)
    let scoredResults = results.compactMap { result -> (ItunesSearchResult, Double)? in
      guard let name = result.artistName, result.artistId != nil else { return nil }
      return (result, jaroWinkler(normalizedArtist, normalize(name)))
    }
    .sorted { $0.1 > $1.1 }

    guard let best = scoredResults.first, best.1 >= 0.96 else { return nil }
    guard scoredResults.count == 1 || best.1 - scoredResults[1].1 >= 0.05 else { return nil }
    return best.0
  }

  private static func isCompatibleEdition(_ left: String, _ right: String) -> Bool {
    let qualifiers: Set<String> = [
      "anniversary", "deluxe", "expanded", "live", "remaster", "remastered",
    ]
    let leftQualifiers = normalize(left)
      .split(separator: " ")
      .map { String($0) }
      .filter { qualifiers.contains($0) }
      .sorted()
    let rightQualifiers = normalize(right)
      .split(separator: " ")
      .map { String($0) }
      .filter { qualifiers.contains($0) }
      .sorted()
    return leftQualifiers == rightQualifiers
  }

  private static func normalize(_ value: String) -> String {
    value
      .folding(
        options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current
      )
      .unicodeScalars
      .map { CharacterSet.alphanumerics.contains($0) ? String($0) : " " }
      .joined()
      .split(whereSeparator: \.isWhitespace)
      .joined(separator: " ")
  }

  private static func jaroWinkler(_ left: String, _ right: String) -> Double {
    if left == right { return 1 }
    if left.isEmpty || right.isEmpty { return 0 }

    let leftCharacters = Array(left)
    let rightCharacters = Array(right)
    let matchingWindow = max(0, max(leftCharacters.count, rightCharacters.count) / 2 - 1)
    var leftMatches = Array(repeating: false, count: leftCharacters.count)
    var rightMatches = Array(repeating: false, count: rightCharacters.count)
    var matches = 0

    for leftIndex in leftCharacters.indices {
      let lowerBound = max(0, leftIndex - matchingWindow)
      let upperBound = min(leftIndex + matchingWindow + 1, rightCharacters.count)
      guard lowerBound < upperBound else { continue }
      for rightIndex in lowerBound ..< upperBound where !rightMatches[rightIndex] {
        guard leftCharacters[leftIndex] == rightCharacters[rightIndex] else { continue }
        leftMatches[leftIndex] = true
        rightMatches[rightIndex] = true
        matches += 1
        break
      }
    }

    if matches == 0 { return 0 }

    let matchedLeft = leftCharacters.indices.filter { leftMatches[$0] }.map { leftCharacters[$0] }
    let matchedRight = rightCharacters.indices.filter { rightMatches[$0] }.map {
      rightCharacters[$0]
    }
    let transpositions = zip(matchedLeft, matchedRight).filter(!=).count / 2
    let matchCount = Double(matches)
    let jaro =
      ((matchCount / Double(leftCharacters.count))
        + (matchCount / Double(rightCharacters.count))
        + ((matchCount - Double(transpositions)) / matchCount)) / 3
    let prefixLength = zip(leftCharacters, rightCharacters).prefix(4).prefix(while: ==).count
    return jaro + (Double(prefixLength) * 0.1 * (1 - jaro))
  }
}
