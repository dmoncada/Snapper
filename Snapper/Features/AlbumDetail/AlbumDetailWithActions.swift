import SwiftUI

struct AlbumDetailWithActions: View {
  let entry: AlbumEntry
  let onDelete: (AlbumEntry) -> Void

  @State private var pendingDelete: AlbumEntry?

  var body: some View {
    AlbumDetailView(entry: entry)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            FavoriteButton(entry: entry)
            DeleteButton {
              pendingDelete = entry
            }
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
      .deleteAlert(for: $pendingDelete) { entry in
        onDelete(entry)
      }
  }
}

#if DEBUG
import SwiftData

#Preview(traits: .withSampleData) {
  @Previewable @Query var entries: [AlbumEntry]
  @Previewable @State var player = PreviewPlayer()

  if let entry = entries.first {
    NavigationStack {
      AlbumDetailWithActions(entry: entry) { _ in
        print("Album deleted")
      }
      .environment(player)
    }
  } else {
    ProgressView()
  }
}
#endif
