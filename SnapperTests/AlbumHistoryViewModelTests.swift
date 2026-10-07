import SwiftData
import Testing

@testable import Snapper

@MainActor
struct AlbumHistoryViewModelTests {
  @Test
  func searchMatchesArtistAndAlbumTitleAndResets() throws {
    let container = try SampleAlbumStore.makeContainer(limit: 4)
    let context = container.mainContext
    let model = AlbumHistoryViewModel(context: context)
    model.searchText = "radioHEAD"
    let artistResults = try context.fetch(model.descriptor)
    #expect(artistResults.map(\.title) == ["Kid A"])

    model.searchText = "art of LOVING"
    let titleResults = try context.fetch(model.descriptor)
    #expect(titleResults.map(\.artist) == ["Olivia Dean"])

    model.searchText = "no matching album"
    let noResults = try context.fetch(model.descriptor)
    #expect(noResults.isEmpty)

    model.searchText = ""
    let allResults = try context.fetch(model.descriptor)
    #expect(allResults.count == 4)
  }

  @Test
  func filtersFavoritesAndClearsSelection() throws {
    let container = try SampleAlbumStore.makeContainer(limit: 2)
    let context = container.mainContext
    let entries = try context.fetch(FetchDescriptor<AlbumEntry>())
    #expect(entries.count == 2)

    let favorite = try #require(entries.first)
    for entry in entries {
      entry.isFavorited = entry.id == favorite.id
    }
    try context.save()

    let model = AlbumHistoryViewModel(context: context)
    model.favoritesOnly = true

    let filtered = try context.fetch(model.descriptor)
    #expect(filtered.map(\.id) == [favorite.id])

    model.isSelecting = true
    model.selectedIds.insert(favorite.id)
    model.cancelSelection()

    #expect(model.isSelecting == false)
    #expect(model.selectedIds.isEmpty)
  }
}
