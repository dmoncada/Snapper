import SwiftUI
import WidgetKit

struct SnapperWidgetEntryView: View {
  let entry: HistoryEntry

  private let columns = [
    GridItem(.flexible(), spacing: 0),
    GridItem(.flexible(), spacing: 0),
    GridItem(.flexible(), spacing: 0),
  ]

  var body: some View {
    GeometryReader { geometry in
      let side = max(geometry.size.width, geometry.size.height) * CGFloat(2).squareRoot()

      LazyVGrid(columns: columns, spacing: 0) {
        ForEach(0 ..< 9, id: \.self) { index in
          if index < entry.albums.count {
            HistoryAlbumTile(album: entry.albums[index])
          } else {
            Color.clear
              .aspectRatio(1, contentMode: .fit)
          }
        }
      }
      .frame(width: side, height: side)
      .rotationEffect(.degrees(45))
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .clipped()
    .containerBackground(.fill.tertiary, for: .widget)
  }
}
