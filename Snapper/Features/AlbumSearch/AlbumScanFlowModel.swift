import Foundation
import Observation

@MainActor
@Observable
final class AlbumScanFlowModel {
  var entry: Album?

  private(set) var scanGeneration = 0
  private(set) var lookupGeneration = 0

  private(set) var message: LocalizedStringResource?

  private(set) var didSave = false
  private(set) var isSearching = false

  private var barcode: String?
  private var isClosed = false

  private let apiClient: any ApiClient

  init(apiClient: any ApiClient = .live) {
    self.apiClient = apiClient
  }

  func accept(_ barcode: String) {
    guard !isClosed, self.barcode == nil else { return }
    self.barcode = barcode
    retry()
  }

  func retry() {
    guard !isClosed, barcode != nil else { return }
    message = nil
    isSearching = true
    lookupGeneration += 1
  }

  func lookup() async {
    guard
      !isClosed,
      isSearching,
      let barcode
    else { return }

    let generation = lookupGeneration

    do {
      let response = try await apiClient.searchAlbums(term: nil, barcode: barcode, limit: 10)
      try Task.checkCancellation()

      // let candidates = response.map(AlbumCandidate.init(dto:))
      let candidates = response.map { Album(dto: $0) }

      guard
        !isClosed,
        generation == lookupGeneration
      else { return }

      isSearching = false

      guard let first = candidates.first else {
        message = "No albums found for this barcode."
        return
      }

      entry = first
    } catch {
      guard
        !Task.isCancelled,
        !isClosed, generation == lookupGeneration
      else { return }

      message = "Could not look up this barcode: \(error.localizedDescription)"
      isSearching = false
    }
  }

  func markSaved() {
    didSave = true
  }

  func reset() {
    if isClosed { return }
    barcode = nil

    entry = nil
    message = nil
    isSearching = false

    scanGeneration += 1
    lookupGeneration += 1
  }

  func close() {
    isClosed = true
    isSearching = false
    lookupGeneration += 1
  }
}
