import Foundation
import Observation

@MainActor
@Observable
final class AlbumSearchViewModel {
  var query = ""
  // var searchMode = AlbumSearchMode.term

  private(set) var searchState = AlbumSearchState.idle
  private(set) var candidates: [AlbumCandidate] = []
  private(set) var isScanningImage = false

  private let client: DiscogsClient
  private let imageRecognitionService: AlbumImageRecognitionService

  convenience init() {
    let token = Bundle.main.object(forInfoDictionaryKey: "DISCOGS_TOKEN") as? String ?? ""
    self.init(
      client: .init(token: token),
      imageRecognitionService: .init())
  }

  init(
    client: DiscogsClient,
    imageRecognitionService: AlbumImageRecognitionService = .init()
  ) {
    self.client = client
    self.imageRecognitionService = imageRecognitionService
  }

  func selection(for candidate: AlbumCandidate) -> AlbumSelection {
    /*
    let barcode =
      searchMode == .barcode ? query.trimmingCharacters(in: .whitespacesAndNewlines) : nil
    return AlbumSelection(candidate: candidate, barcode: barcode)
     */
    AlbumSelection(candidate: candidate, barcode: nil)
  }

  func recognizeAndSearch(imageData: Data) async {
    isScanningImage = true
    defer { isScanningImage = false }

    // searchMode = .term
    query = ""
    candidates = []
    searchState = .recognizing

    do {
      let recognition = try await imageRecognitionService.recognize(in: imageData)
      try Task.checkCancellation()

      guard recognition.barcode != nil || recognition.textQuery != nil else {
        searchState = .unreadable
        return
      }

      searchState = .searching

      if let barcode = recognition.barcode {
        // searchMode = .barcode
        query = barcode

        let barcodeCandidates = try await client.searchAlbums(withBarcode: barcode)
        try Task.checkCancellation()

        candidates = barcodeCandidates

        if !barcodeCandidates.isEmpty {
          searchState = .results
          return
        }
      }

      guard let textQuery = recognition.textQuery else {
        searchState = .empty
        return
      }

      // searchMode = .term
      query = textQuery

      let textCandidates = try await client.searchAlbums(matching: textQuery)
      try Task.checkCancellation()

      searchState = textCandidates.isEmpty ? .empty : .results
      candidates = textCandidates

    } catch is CancellationError {
      // A newer input or view lifecycle event replaced this scan.

    } catch {
      searchState = .error(error.localizedDescription)
      candidates = []
    }
  }

  func reportImageImportError(_ message: String) {
    candidates = []
    searchState = .error(message)
  }

  func search(debounceDuration: Duration = .seconds(1)) async {
    if isScanningImage { return }

    let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
    // let searchMode = searchMode

    if query.isEmpty {
      candidates = []
      searchState = .idle
      return
    }

    searchState = .searching

    do {
      try await Task.sleep(for: debounceDuration)
      try Task.checkCancellation()

      /*
      let candidates =
        switch searchMode {
        case .term:
          try await client.searchAlbums(matching: query)
        case .barcode:
          try await client.searchAlbums(withBarcode: query)
        }
       */

      let candidates = try await client.searchAlbums(matching: query)

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

enum AlbumSearchState: Equatable {
  case idle
  case recognizing
  case searching
  case results
  case empty
  case unreadable
  case error(String)
}
