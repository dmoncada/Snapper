import SwiftData
import SwiftUI

struct FavoriteButton: View {
  let entry: AlbumEntry

  var body: some View {
    Button {
      entry.isFavorited.toggle()
    } label: {
      HStack {
        Image(
          systemName:
            entry.isFavorited
            ? "star.slash"
            : "star"
        )

        Text(
          entry.isFavorited
            ? "Undo Favorite"
            : "Favorite"
        )
      }
    }
  }
}

struct DeleteButton: View {
  let action: () -> Void

  var body: some View {
    Button(role: .destructive) {
      action()
    } label: {
      Label("Delete from History", systemImage: "trash")
    }
  }
}

#if DEBUG
import SwiftData

#Preview(traits: .withSampleData) {
  @Previewable @Query var entries: [AlbumEntry]

  if let entry = entries.first {
    NavigationStack {
      Text("Hello, world!")
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Menu {
              FavoriteButton(entry: entry)
              DeleteButton {}
            } label: {
              Image(systemName: "ellipsis")
            }
          }
        }
    }
  } else {
    ProgressView()
  }
}
#endif
