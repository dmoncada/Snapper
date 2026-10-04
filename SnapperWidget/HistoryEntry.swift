import WidgetKit

struct HistoryEntry: TimelineEntry {
  let date: Date
  let albumCount: Int
  let newestTitle: String?
}
