import SwiftUI
import WidgetKit

struct SnapperWidget: Widget {
  let kind = "SnapperWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: SnapperWidgetProvider()) { entry in
      SnapperWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("MusicSnap History")
    .description("Shows recently saved albums.")
    .supportedFamilies([
      .systemSmall,
      .systemMedium,
    ])
  }
}

#Preview(as: .systemSmall) {
  SnapperWidget()
} timeline: {
  HistoryEntry(
    date: .now,
    albumCount: 2,
    newestTitle: "A recent album",
  )
}
