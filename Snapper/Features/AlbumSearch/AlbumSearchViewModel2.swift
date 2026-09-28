import Foundation
import Observation

@MainActor
@Observable
class AlbumSearchViewModel2 {
  private let discogsClient: DiscogsClient

  private(set) var state: State = .idle
  private(set) var results: [AlbumCandidate] = []

  var searchText = ""

  convenience init() {
    let token = Bundle.main.object(forInfoDictionaryKey: "DISCOGS_TOKEN") as? String ?? ""
    self.init(discogsClient: .init(token: token))
  }

  init(discogsClient: DiscogsClient) {
    self.discogsClient = discogsClient
  }

  func search(debounceDuration: Duration = .seconds(1)) async {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    if query.isEmpty {
      state = .idle
      results = []
      return
    }

    state = .searching

    do {
      try await Task.sleep(for: debounceDuration)
      try Task.checkCancellation()

      results = try await discogsClient.searchAlbums(matching: query, limit: 10)
      try Task.checkCancellation()

      state =
        results.isEmpty
        ? .empty
        : .results

    } catch is CancellationError {
      // A newer input replaces this request.

    } catch {
      state = .error(error.localizedDescription)
      results = []
    }
  }
}

extension AlbumSearchViewModel2 {
  enum State: Equatable {
    case idle
    case recognizing
    case searching
    case results
    case empty
    case unreadable
    case error(String)
  }
}
