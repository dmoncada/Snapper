import Foundation
import Observation

@MainActor
@Observable
class AlbumSearchViewModel {
  var searchText = ""

  private(set) var state: State = .idle
  private(set) var results: [AlbumCandidate] = []

  private let apiClient: SnapperApiClient
  private var recognizer = ImageRecognitionService()
  private var scannedBarcode: String?

  init() {
    apiClient = SnapperApiClient()
  }

  func showScannedBarcode(_ barcode: String) {
    scannedBarcode = barcode
    searchText = barcode
  }

  func recognize(in data: Data) async throws {
    state = .recognizing

    let result = try await recognizer.recognize(in: data)
    try Task.checkCancellation()

    guard let barcode = result.barcode else {
      state = .unreadable
      return
    }

    return await search(barcode, debounceDuration: .zero, isBarcode: true)
  }

  func search(debounceDuration: Duration = .seconds(1)) async {
    await search(
      searchText,
      debounceDuration: debounceDuration,
      isBarcode: searchText == scannedBarcode,
    )
  }

  private func search(_ query: String, debounceDuration: Duration, isBarcode: Bool) async {
    let query = query.trimmingCharacters(in: .whitespacesAndNewlines)

    if query.isEmpty {
      state = .idle
      results = []
      return
    }

    state = .searching

    do {
      try await Task.sleep(for: debounceDuration)
      try Task.checkCancellation()

      if isBarcode {
        results = try await apiClient.searchAlbums(withBarcode: query)
      } else {
        results = try await apiClient.searchAlbums(matching: query)
      }
      try Task.checkCancellation()

      state = results.isEmpty ? .empty : .results
    } catch is CancellationError {
      // A newer input replaces this request.
    } catch {
      state = .error(error.localizedDescription)
      results = []
    }
  }
}

extension AlbumSearchViewModel {
  enum State: Equatable, CustomStringConvertible {
    case idle
    case recognizing
    case searching
    case results
    case empty
    case unreadable
    case error(String)

    var description: String {
      switch self {
      case .idle: return "Idle"
      case .recognizing: return "Recognizing"
      case .searching: return "Searching"
      case .results: return "Results"
      case .empty: return "No results"
      case .unreadable: return "Unreadable"
      case .error(let message): return "Error: \(message)"
      }
    }
  }
}
