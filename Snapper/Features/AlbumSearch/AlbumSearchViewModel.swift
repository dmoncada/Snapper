import Foundation
import Observation

@MainActor
@Observable
final class AlbumSearchViewModel {
  var query = ""
  var searchMode = AlbumSearchMode.term

  private(set) var searchState = AlbumSearchState.idle
  private(set) var candidates: [AlbumCandidate] = []

  private let client: DiscogsClient

  convenience init() {
    let token = Bundle.main.object(forInfoDictionaryKey: "DISCOGS_TOKEN") as? String ?? ""
    self.init(client: DiscogsClient(token: token))
  }

  init(client: DiscogsClient) {
    self.client = client
  }

  func selection(for candidate: AlbumCandidate) -> AlbumSelection {
    let barcode =
      searchMode == .barcode ? query.trimmingCharacters(in: .whitespacesAndNewlines) : nil
    return AlbumSelection(candidate: candidate, barcode: barcode)
  }

  func search() async {
    let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let searchMode = searchMode

    if query.isEmpty {
      candidates = []
      searchState = .idle
      return
    }

    searchState = .searching

    do {
      try await Task.sleep(for: .seconds(1))
      try Task.checkCancellation()

      let candidates =
        switch searchMode {
        case .term:
          try await client.searchAlbums(matching: query)
        case .barcode:
          try await client.searchAlbums(withBarcode: query)
        }

      try Task.checkCancellation()
      self.candidates = candidates
      searchState = candidates.isEmpty ? .empty : .results

    } catch is CancellationError {
      // A newer input replaces this request.

    } catch {
      candidates = []
      searchState = .error(error.localizedDescription)
    }
  }
}
