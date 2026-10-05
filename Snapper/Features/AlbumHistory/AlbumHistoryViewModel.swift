import SwiftData
import SwiftUI
import WidgetKit
import os

@MainActor
@Observable
class AlbumHistoryViewModel {
  var searchText = ""
  var favoritesOnly = false
  var sort = SortModel()

  var isSelecting = false
  var selectedIds: Set<UUID> = []

  private let context: ModelContext

  init(context: ModelContext) {
    self.context = context
  }

  var descriptor: FetchDescriptor<AlbumEntry> {
    let criterion = sort.criterion
    let order = sort.getOrder(for: criterion)

    var descriptor = FetchDescriptor<AlbumEntry>(
      predicate: #Predicate { entry in
        favoritesOnly == false || entry.isFavorited
      }
    )

    let sortDescriptor: SortDescriptor<AlbumEntry>

    switch criterion {
    case .dateFound:
      sortDescriptor = SortDescriptor(
        \.selectedAt,
        order: order == .newestFirst ? .reverse : .forward,
      )

    case .albumTitle:
      sortDescriptor = SortDescriptor(
        \.title,
        order: order == .ascending ? .forward : .reverse,
      )

    case .artistName:
      sortDescriptor = SortDescriptor(
        \.artist,
        order: order == .ascending ? .forward : .reverse,
      )
    }

    descriptor.sortBy = [sortDescriptor]

    return descriptor
  }

  var currentOrder: Binding<SortOrder> {
    Binding(
      get: { self.sort.getOrder(for: self.sort.criterion) },
      set: { self.sort.setOrder($0, for: self.sort.criterion) },
    )
  }

  func cancelSelection() {
    selectedIds.removeAll()
    isSelecting = false
  }

  func delete(_ entry: AlbumEntry) {
    context.delete(entry)
    saveAndReloadWidget()
  }

  func batchDelete(ids: Set<AlbumEntry.ID>) {
    guard let history = try? context.fetch(FetchDescriptor<AlbumEntry>()) else { return }

    for entry in history where ids.contains(entry.id) {
      context.delete(entry)
    }

    saveAndReloadWidget()
    cancelSelection()
  }

  private func saveAndReloadWidget() {
    do {
      try context.save()
      WidgetCenter.shared.reloadTimelines(ofKind: "SnapperWidget")
    } catch {
      Logger(subsystem: "net.dmoncada.Snapper", category: "AlbumHistory")
        .error("History save failed: \(error.localizedDescription, privacy: .public)")
    }
  }
}
