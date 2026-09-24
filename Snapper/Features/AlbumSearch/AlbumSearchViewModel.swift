import Foundation
import Observation

@MainActor
@Observable
final class AlbumSearchViewModel {
  var query = ""
  var searchMode = AlbumSearchMode.term

  private(set) var searchState = AlbumSearchState.idle
  private(set) var candidates: [AlbumCandidate] = []
  private(set) var isScanningImage = false

  private let client: DiscogsClient
  private let imageRecognitionService: AlbumImageRecognitionService

  convenience init() {
    let token = Bundle.main.object(forInfoDictionaryKey: "DISCOGS_TOKEN") as? String ?? ""
    self.init(
      client: DiscogsClient(token: token),
      imageRecognitionService: AlbumImageRecognitionService())
  }

  init(
    client: DiscogsClient,
    imageRecognitionService: AlbumImageRecognitionService = AlbumImageRecognitionService()
  ) {
    self.client = client
    self.imageRecognitionService = imageRecognitionService
  }

  func selection(for candidate: AlbumCandidate) -> AlbumSelection {
    let barcode =
      searchMode == .barcode ? query.trimmingCharacters(in: .whitespacesAndNewlines) : nil
    return AlbumSelection(candidate: candidate, barcode: barcode)
  }

  func recognizeAndSearch(imageData: Data) async {
    isScanningImage = true
    defer { isScanningImage = false }

    searchMode = .term
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
        searchMode = .barcode
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

      searchMode = .term
      query = textQuery

      let textCandidates = try await client.searchAlbums(matching: textQuery)
      try Task.checkCancellation()
      candidates = textCandidates
      searchState = textCandidates.isEmpty ? .empty : .results

    } catch is CancellationError {
      // A newer input or view lifecycle event replaced this scan.

    } catch {
      candidates = []
      searchState = .error(error.localizedDescription)
    }
  }

  func reportImageImportError(_ message: String) {
    candidates = []
    searchState = .error(message)
  }

  func search() async {
    guard !isScanningImage else { return }

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
