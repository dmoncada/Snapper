import Foundation
import Observation

@MainActor
@Observable
final class AlbumScanFlowModel {
  private(set) var scanGeneration = 0
  private(set) var lookupGeneration = 0

  private(set) var results: [AlbumCandidate] = []
  private(set) var message: LocalizedStringResource?
  private(set) var selectedEntry: AlbumEntry?

  private(set) var didSave = false
  private(set) var isSearching = false

  var isShowingAlbum = false

  private var barcode: String?
  private var isClosed = false
  private let client: DiscogsClient

  init() {
    let token = Bundle.main.object(forInfoDictionaryKey: "DISCOGS_TOKEN") as? String ?? ""
    client = DiscogsClient(token: token)
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
      let candidates = try await client.searchAlbums(matching: barcode, limit: 10)
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
      isShowingAlbum = true
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
    selectedEntry = AlbumEntry(candidate: candidate)
  }

  func showAllResults() {
    selectedEntry = nil
  }

  func markSaved() {
    didSave = true
  }

  func scanAgain() {
    if isClosed { return }
    barcode = nil

    results = []
    message = nil
    isSearching = false
    selectedEntry = nil

    scanGeneration += 1
    lookupGeneration += 1
  }

  func close() {
    isClosed = true
    isSearching = false
    lookupGeneration += 1
  }
}
