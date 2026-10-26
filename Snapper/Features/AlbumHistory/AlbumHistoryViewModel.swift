import SwiftData
import SwiftUI
import WidgetKit
import os

@MainActor
@Observable
final class AlbumHistoryViewModel {
  var searchText = ""
  var favoritesOnly = false
  var sort = SortModel()

  var isSelecting = false
  var selectedIds: Set<Album.ID> = []

  init(context: ModelContext) {
    self.context = context
  }

  @ObservationIgnored private let context: ModelContext

  var descriptor: FetchDescriptor<Album> {
    let criterion = sort.criterion
    let order = sort.getOrder(for: criterion)

    let isFavorite = #Predicate<Album> { album in
      favoritesOnly == false || album.isFavorite
    }

    let isMatch = #Predicate<Album> { album in
      searchText.isEmpty
        || album.artist.localizedStandardContains(searchText)
        || album.title.localizedStandardContains(searchText)
    }

    var descriptor = FetchDescriptor<Album>(
      predicate: #Predicate { album in
        isFavorite.evaluate(album) && isMatch.evaluate(album)
      }
    )

    let sortDescriptor: SortDescriptor<Album>

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

  var albumCount: Int {
    context.getCount(for: Album.self)
  }

  var filteredCount: Int {
    context.getCount(using: descriptor)
  }

  var currentOrder: Binding<SortOrder> {
    Binding(
      get: { self.sort.getOrder(for: self.sort.criterion) },
      set: { self.sort.setOrder($0, for: self.sort.criterion) },
    )
  }

  func clearSelection() {
    selectedIds.removeAll()
    isSelecting = false
  }

  func delete(_ album: Album) {
    context.delete(album)
    saveAndReloadWidget()
  }

  func batchDelete(ids: Set<Album.ID>) {
    guard let history = try? context.fetch(FetchDescriptor<Album>()) else { return }

    for album in history where ids.contains(album.id) {
      context.delete(album)
    }

    saveAndReloadWidget()
    clearSelection()
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
