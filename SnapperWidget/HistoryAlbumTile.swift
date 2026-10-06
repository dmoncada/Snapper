import ImageIO
import SwiftUI

struct HistoryAlbumTile: View {
  let album: HistoryAlbum

  var body: some View {
    Rectangle()
      .fill(.placeholder)
      .aspectRatio(1, contentMode: .fit)
      .overlay {
        if let data = album.imageData,
          let source = CGImageSourceCreateWithData(data as CFData, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        {
          Image(decorative: image, scale: 1)
            .resizable()
            .scaledToFill()
        } else {
          Image(systemName: "opticaldisc")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.primary)
        }
      }
      .clipped()
  }
}
