import Logging
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
@Observable
final class AlbumHistoryViewModel {
  var searchText = ""
  var selectedFilters: Set<AlbumHistoryFilter> = [.all]
  var sort = SortModel()

  var isSelecting = false
  var selectedIds: Set<Album.ID> = []

  private(set) var availableFilters: [AlbumHistoryFilter] = [
    .all,
    .favorites,
  ]

  private let logger: Logger
  private let context: ModelContext

  init(
    logger: Logger = .current,
    context: ModelContext,
  ) {
    self.logger = logger
    self.context = context
    refreshAvailableFilters()
  }

  func refreshAvailableFilters() {
    let albums = (try? context.fetch(FetchDescriptor<Album>())) ?? []

    let genres = Set(albums.flatMap(\.genre).map(\.name))

    availableFilters =
      [
        .all,
        .favorites,
      ]
      + genres.sorted().map(AlbumHistoryFilter.genre)
  }

  subscript(isSelected filter: AlbumHistoryFilter) -> Bool {
    get { selectedFilters.contains(filter) }
    set {
      if newValue == selectedFilters.contains(filter) { return }
      toggleFilter(filter)
    }
  }

  func toggleFilter(_ filter: AlbumHistoryFilter) {
    if filter == .all {
      selectedFilters = [.all]
      return
    }

    selectedFilters.remove(.all)

    if selectedFilters.contains(filter) {
      selectedFilters.remove(filter)
    } else {
      selectedFilters.insert(filter)
    }

    if selectedFilters.isEmpty {
      selectedFilters = [.all]
    }
  }

  var descriptor: FetchDescriptor<Album> {
    let criterion = sort.criterion
    let order = sort.getOrder(for: criterion)

    let favoritesOnly = selectedFilters.contains(.favorites)

    let isFavorite = #Predicate<Album> { album in
      favoritesOnly == false || album.isFavorite
    }

    let isMatch = #Predicate<Album> { album in
      searchText.isEmpty
        || album.artist.localizedStandardContains(searchText)
        || album.title.localizedStandardContains(searchText)
    }

    let selectedGenreNames = selectedFilters.compactMap { filter in
      if case .genre(let name) = filter { return name }
      return nil
    }

    let isGenre: Predicate<Album>
    if selectedGenreNames.isEmpty {
      isGenre = #Predicate { _ in true }
    } else {
      isGenre = #Predicate { album in
        album.genre.contains { genre in
          selectedGenreNames.contains(genre.name)
        }
      }
    }

    var descriptor = FetchDescriptor<Album>(
      predicate: #Predicate { album in
        isFavorite.evaluate(album)
          && isMatch.evaluate(album)
          && isGenre.evaluate(album)
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
    refreshAvailableFilters()
    saveAndReloadWidget()
  }

  func batchDelete(ids: Set<Album.ID>) {
    guard let history = try? context.fetch(FetchDescriptor<Album>()) else { return }

    for album in history where ids.contains(album.id) {
      context.delete(album)
    }

    refreshAvailableFilters()
    saveAndReloadWidget()
    clearSelection()
  }

  private func saveAndReloadWidget() {
    do {
      try context.save()
      WidgetCenter.shared.reloadTimelines(ofKind: "SnapperWidget")
    } catch {
      logger.error("History save failed.", error: error)
    }
  }
}
