import SwiftData
import WidgetKit
import os

struct SnapperWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> HistoryEntry {
    HistoryEntry(date: .now, albums: [])
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (HistoryEntry) -> Void,
  ) {
    Task {
      completion(await readHistory())
    }
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<HistoryEntry>) -> Void,
  ) {
    Task {
      completion(Timeline(entries: [await readHistory()], policy: .never))
    }
  }

  @MainActor
  private func readHistory() async -> HistoryEntry {
    let logger = Logger(subsystem: "net.dmoncada.Snapper", category: "WidgetHistory")

    do {
      let container = try SharedAlbumStore.makeContainer()
      let context = ModelContext(container)

      var fetch = FetchDescriptor<AlbumEntry>()
      let sort = SortDescriptor(\AlbumEntry.selectedAt, order: .reverse)

      fetch.sortBy = [sort]
      fetch.fetchLimit = 9

      let sources = try context.fetch(fetch).map { album in
        (
          id: album.id,
          title: album.title,
          imageUrlString: album.thumbnailUrlString ?? album.coverImageUrlString
        )
      }

      logger.info("Widget read \(sources.count) history albums")
      var imageData = [Data?](repeating: nil, count: sources.count)

      await withTaskGroup(of: (Int, Data?).self) { group in
        for (index, source) in sources.enumerated() {
          let imageUrlString = source.imageUrlString
          group.addTask {
            (index, await HistoryAlbumImageLoader.load(from: imageUrlString))
          }
        }

        for await (index, data) in group {
          imageData[index] = data
        }
      }

      let albums = sources.enumerated().map { index, source in
        HistoryAlbum(
          id: source.id,
          title: source.title,
          imageData: imageData[index]
        )
      }
      return HistoryEntry(date: .now, albums: albums)
    } catch {
      logger.error("Widget history read failed: \(error.localizedDescription, privacy: .public)")
      return HistoryEntry(date: .now, albums: [])
    }
  }
}
