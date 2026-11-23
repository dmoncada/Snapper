import SwiftUI

struct AlbumDetailWithActions: View {
  let album: Album
  let deleteAction: () -> Void

  @State private var alert: AlertDestination?

  var body: some View {
    @Bindable var album = album

    AdaptiveAlbumDetailView(album: album)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            FavoriteButton(isFavorite: $album.isFavorite)
            DeleteButton(title: .toolsDeleteHistory) {
              alert = AlertDestination(
                title: .alertsHistoryDeleteTitle(count: 1),
                message: .alertsHistoryDeleteMessage(count: 1),
                primary: .delete { deleteAction() },
                secondary: .cancel,
              )
            }
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
      .withAlertDestination($alert)
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
