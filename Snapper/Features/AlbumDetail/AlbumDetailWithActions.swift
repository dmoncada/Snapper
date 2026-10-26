import SwiftUI

struct AlbumDetailWithActions: View {
  @Environment(Router.self) private var router

  let album: Album
  let onDelete: (Album) -> Void

  var body: some View {
    AlbumDetailView(album: album)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            FavoriteButton(album: album)
            DeleteButton {
              router.alertItem = AlertDestination(
                title: "Delete Album?",
                message: "Do you want to delete \"\(album.title)\" from your history?",
                primary: .delete { onDelete(album) },
                secondary: .cancel,
              )
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
  @Previewable @State var router = Router()

  if let album = albums.first {
    NavigationStack {
      AlbumDetailWithActions(album: album) { _ in
        print("Album deleted")
      }
      .withAlertDestination($router.alertItem)
      .environment(\.previewPlayer, .live)
      .environment(router)
    }
  } else {
    ProgressView()
  }
}
#endif
