import SwiftUI

struct AlbumDetailWithActions: View {
  @Environment(Router.self) private var router

  let entry: AlbumEntry
  let onDelete: (AlbumEntry) -> Void

  var body: some View {
    AlbumDetailView(entry: entry)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            FavoriteButton(entry: entry)
            DeleteButton {
              router.alertItem = AlertDestination(
                title: "Delete Album?",
                message: "Do you want to delete \"\(entry.title)\" from your history?",
                primary: .delete { onDelete(entry) },
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
  @Previewable @Query var entries: [AlbumEntry]
  @Previewable @State var player = PreviewPlayer()
  @Previewable @State var router = Router()

  if let entry = entries.first {
    NavigationStack {
      AlbumDetailWithActions(entry: entry) { _ in
        print("Album deleted")
      }
      .withAlertDestination($router.alertItem)
      .environment(player)
      .environment(router)
    }
  } else {
    ProgressView()
  }
}
#endif
