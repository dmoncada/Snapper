import SwiftData
import Testing

@testable import Snapper

@MainActor
struct AlbumHistoryViewModelTests {
  @Test
  func filtersFavoritesAndClearsSelection() throws {
    let container = try SampleAlbumStore.makeContainer(limit: 2)
    let context = container.mainContext
    let entries = try context.fetch(FetchDescriptor<AlbumEntry>())
    #expect(entries.count == 2)

    let favorite = try #require(entries.first)
    favorite.isFavorited = true
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
