import SwiftData
import SwiftUI

struct FavoriteButton: View {
  let album: Album

  var body: some View {
    Button {
      album.isFavorite.toggle()
    } label: {
      HStack {
        Image(
          systemName:
            album.isFavorite
            ? "star.slash"
            : "star"
        )

        Text(
          album.isFavorite
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
  @Previewable @Query var albums: [Album]

  if let album = albums.first {
    NavigationStack {
      Text("Hello, world!")
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Menu {
              FavoriteButton(album: album)
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
