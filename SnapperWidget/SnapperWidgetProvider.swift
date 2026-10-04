import SwiftData
import WidgetKit
import os

struct SnapperWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> HistoryEntry {
    HistoryEntry(date: .now, albumCount: 0, newestTitle: nil)
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (HistoryEntry) -> Void,
  ) {
    completion(readHistory())
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<HistoryEntry>) -> Void,
  ) {
    completion(Timeline(entries: [readHistory()], policy: .never))
  }

  private func readHistory() -> HistoryEntry {
    let logger = Logger(subsystem: "net.dmoncada.Snapper", category: "WidgetHistory")

    do {
      let container = try SharedAlbumStore.makeContainer()
      let modelContext = ModelContext(container)

      let sort = SortDescriptor(\AlbumEntry.selectedAt)
      var fetch = FetchDescriptor<AlbumEntry>(sortBy: [sort])
      fetch.fetchLimit = 8

      let albums = try modelContext.fetch(fetch)
      logger.info("Widget read \(albums.count) history albums")

      return HistoryEntry(
        date: .now,
        albumCount: albums.count,
        newestTitle: albums.first?.title,
      )
    } catch {
      logger.error("Widget history read failed: \(error.localizedDescription, privacy: .public)")
      return HistoryEntry(date: .now, albumCount: 0, newestTitle: nil)
    }
  }
}
