import Observation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class HistoryViewModel {
  var searchText = ""
  var favoritesOnly = false
  var sort = SortModel()

  var isSelecting = false
  var selectedIds: Set<UUID> = []

  private let context: ModelContext

  init(context: ModelContext) {
    self.context = context
  }

  var currentOrder: Binding<SortOrder> {
    Binding(
      get: { self.sort.getOrder(for: self.sort.criterion) },
      set: { self.sort.setOrder($0, for: self.sort.criterion) },
    )
  }

  func toggleSelection(for entry: AlbumEntry) {
    if selectedIds.insert(entry.id).inserted == false {
      selectedIds.remove(entry.id)
    }
  }

  func cancelSelection() {
    selectedIds.removeAll()
    isSelecting = false
  }

  func delete(_ entry: AlbumEntry) {
    context.delete(entry)
  }

  func batchDelete(ids: Set<AlbumEntry.ID>) {
    guard let history = try? context.fetch(descriptor) else { return }

    for entry in history where ids.contains(entry.id) {
      context.delete(entry)
    }

    cancelSelection()
  }

  // func fetchHistory() throws -> [AlbumEntry] {
  var descriptor: FetchDescriptor<AlbumEntry> {
    // do {
    let criterion = sort.criterion
    let order = sort.getOrder(for: criterion)

    var descriptor = FetchDescriptor<AlbumEntry>(
      predicate: #Predicate { entry in
        favoritesOnly == false || entry.isFavorited
      }
    )

    switch criterion {
    case .dateFound:
      descriptor.sortBy = [
        SortDescriptor(
          \.selectedAt,
          order: order == .newestFirst
            ? .reverse
            : .forward,
        )
      ]

    case .albumTitle:
      descriptor.sortBy = [
        SortDescriptor(
          \.title,
          order: order == .ascending
            ? .forward
            : .reverse,
        )
      ]

    case .artistName:
      descriptor.sortBy = [
        SortDescriptor(
          \.artist,
          order: order == .ascending
            ? .forward
            : .reverse,
        )
      ]
    }

    return descriptor
  }

  /*
      var results = try context.fetch(descriptor)

      let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      if query.count > 0 {
        results = results.filter { entry in
          let hasTitle = entry.title.localizedCaseInsensitiveContains(query)
          let hasArtist = entry.artist.localizedCaseInsensitiveContains(query)
          return hasTitle || hasArtist
        }
      }

      return results
    }
  }
   */
}
