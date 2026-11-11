import SwiftUI

struct AlbumClusterView: View {
  let albums: [Album]
  let onSelect: (Album) -> Void

  var body: some View {
    ScrollView {
      ThemeSection {
        ForEach(albums) { album in
          Button {
            onSelect(album)
          } label: {
            AlbumClusterRow(album: album)
              .contentShape(.rect)
          }
          .buttonStyle(.plain)
        }

        Spacer()
      }
      .padding(Padding.xxl)
    }
    .containerBackground(for: .navigation) {
      Rectangle()
        .fill(.ultraThinMaterial)
        .overlay {
          Color.themeBackground.opacity(0.25)
        }
    }
  }
}
