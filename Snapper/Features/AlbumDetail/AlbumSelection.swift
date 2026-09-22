import Foundation

nonisolated struct AlbumSelection: Hashable, Sendable {
  let candidate: AlbumCandidate
  let barcode: String?
}
