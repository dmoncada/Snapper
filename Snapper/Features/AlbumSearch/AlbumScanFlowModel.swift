import Foundation
import Observation

@MainActor
@Observable
final class AlbumScanFlowModel {
  private(set) var scanGeneration = 0
  private(set) var lookupGeneration = 0

  var entry: AlbumEntry?

  private(set) var results: [AlbumCandidate] = []
  private(set) var message: LocalizedStringResource?

  private(set) var didSave = false
  private(set) var isSearching = false

  private var barcode: String?
  private var isClosed = false
  private let client: SnapperApiClient

  init() {
    client = SnapperApiClient()
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
      let candidates = try await client.searchAlbums(withBarcode: barcode)
      try Task.checkCancellation()

      guard
        !isClosed,
        generation == lookupGeneration
      else { return }

      isSearching = false
      results = candidates

      guard let first = candidates.first else {
        message = "No albums found for this barcode."
        return
      }

      select(first)
    } catch {
      guard
        !Task.isCancelled,
        !isClosed, generation == lookupGeneration
      else { return }

      message = "Could not look up this barcode: \(error.localizedDescription)"
      isSearching = false
    }
  }

  func select(_ candidate: AlbumCandidate) {
    entry = AlbumEntry(candidate: candidate)
  }

  func markSaved() {
    didSave = true
  }

  func reset() {
    if isClosed { return }
    barcode = nil

    entry = nil
    results = []
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
