import SwiftUI
import WidgetKit

struct SnapperWidgetEntryView: View {
  let entry: HistoryEntry

  var body: some View {
    let gridSize = entry.albums.count < 9 ? 2 : 3
    let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: gridSize)

    GeometryReader { geometry in
      let side = max(geometry.size.width, geometry.size.height) * CGFloat(2).squareRoot()

      LazyVGrid(columns: columns, spacing: 0) {
        ForEach(0 ..< gridSize * gridSize, id: \.self) { index in
          if index < entry.albums.count {
            HistoryAlbumTile(album: entry.albums[index])
          } else {
            Color.clear
              .aspectRatio(1, contentMode: .fit)
          }
        }
      }
      .frame(
        width: side,
        height: side,
      )
      .rotationEffect(.degrees(45))
      .frame(
        width: geometry.size.width,
        height: geometry.size.height,
      )
    }
    .clipped()
    .containerBackground(.fill.tertiary, for: .widget)
    .overlay(alignment: .topTrailing) {
      Text("MusicSnap")
        .font(.basteleurBold(.caption))
        .foregroundStyle(.white)
        .padding(.trailing, 12)
        .padding(.top, 8)
    }
  }
}
