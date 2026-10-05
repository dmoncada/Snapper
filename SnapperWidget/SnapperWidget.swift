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
    .supportedFamilies([.systemSmall])
    .contentMarginsDisabled()
  }
}

#if DEBUG
#Preview("Empty", as: .systemSmall) {
  SnapperWidget()
} timeline: {
  await HistoryEntry.preview(albumCount: 0)
}

#Preview("One album", as: .systemSmall) {
  SnapperWidget()
} timeline: {
  await HistoryEntry.preview(albumCount: 1)
}

#Preview("Four albums", as: .systemSmall) {
  SnapperWidget()
} timeline: {
  await HistoryEntry.preview(albumCount: 4)
}

#Preview("Nine albums", as: .systemSmall) {
  SnapperWidget()
} timeline: {
  await HistoryEntry.preview(albumCount: 9)
}
#endif
