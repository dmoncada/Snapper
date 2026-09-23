import Foundation

struct AlbumDetailRoute: Hashable, Sendable {
  let selection: AlbumSelection
  let historyEntryID: UUID
}
