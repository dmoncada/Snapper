import SwiftUI

struct AlbumDetailWithActions: View {
  let album: Album
  let deleteAction: () -> Void

  var body: some View {
    @Bindable var album = album

    AlbumDetailView(album: album)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            FavoriteButton(isFavorite: $album.isFavorite)
            DeleteButton {
              deleteAction()
            }
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
  }
}

#if DEBUG
import SwiftData

#Preview(traits: .withSampleData) {
  @Previewable @Query var albums: [Album]

  if let album = albums.first {
    NavigationStack {
      AlbumDetailWithActions(album: album) {
        print("Album deleted")
      }
      .environment(AlbumDetailViewModel())
      .environment(\.previewPlayer, .live)
    }
  } else {
    ProgressView()
  }
}
#endif
