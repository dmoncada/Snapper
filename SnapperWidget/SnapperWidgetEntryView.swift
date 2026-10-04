import SwiftUI
import WidgetKit

struct SnapperWidgetEntryView: View {
  let entry: HistoryEntry

  var body: some View {
    VStack(alignment: .leading) {
      Label("MusicSnap", systemImage: "opticaldisc")
        .bold()

      Text("History: \(entry.albumCount)")

      if let newestTitle = entry.newestTitle {
        Text(newestTitle)
          .lineLimit(1)
      }
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .topLeading,
    )
    .containerBackground(
      .fill.tertiary,
      for: .widget,
    )
  }
}
