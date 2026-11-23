import SwiftUI
import WidgetKit

struct SnapperWidgetEntryView: View {
  let entry: HistoryEntry

  var body: some View {
    let gridSize = entry.albums.count <= 4 ? 2 : 3

    GeometryReader { geometry in
      let side = max(geometry.size.width, geometry.size.height) * CGFloat(2).squareRoot()
      let tileSide = side / CGFloat(gridSize)

      Canvas { context, size in
        guard let grid = context.resolveSymbol(id: 0) else { return }

        context.clip(to: Path(CGRect(origin: .zero, size: size)))
        context.translateBy(x: size.width / 2, y: size.height / 2)
        context.rotate(by: .degrees(45))
        context.draw(grid, at: .zero)
      } symbols: {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
          ForEach(0 ..< gridSize, id: \.self) { row in
            GridRow {
              ForEach(0 ..< gridSize, id: \.self) { column in
                let index = row * gridSize + column
                Group {
                  if index < entry.albums.count {
                    HistoryAlbumTile(album: entry.albums[index])
                  } else {
                    Color.clear
                  }
                }
                .frame(width: tileSide, height: tileSide)
              }
            }
          }
        }
        .frame(width: side, height: side)
        .tag(0)
      }
    }
    .clipped()
    .containerBackground(.fill.tertiary, for: .widget)
    .overlay(alignment: .topTrailing) {
      logo
    }
    .overlay(alignment: .bottomTrailing) {
      if let url = AppDeepLink.camera.url {
        cameraButton(url)
      }
    }
  }

  private var logo: some View {
    Image(.musicSnapMini)
      .resizable()
      .scaledToFit()
      .frame(height: 16)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .foregroundStyle(
        entry.albums.isEmpty
          ? Color.primary
          : Color.white
      )
  }

  @ViewBuilder
  private func cameraButton(_ url: URL) -> some View {
    let size: CGFloat = 28

    Link(destination: url) {
      Image(systemName: "camera.fill")
        .resizable()
        .scaledToFit()
        .frame(width: size, height: size)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .foregroundStyle(
          entry.albums.isEmpty
            ? Color.primary
            : Color.white
        )
    }
  }
}
