import SwiftData
import SwiftUI

struct FavoriteButton: View {
  @Binding var isFavorite: Bool

  var body: some View {
    Button {
      isFavorite.toggle()
    } label: {
      HStack {
        Image(
          systemName:
            isFavorite
            ? "heart.slash"
            : "heart"
        )

        Text(
          isFavorite
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
    @Bindable var album = album

    NavigationStack {
      Text("Hello, world!")
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Menu {
              FavoriteButton(isFavorite: $album.isFavorite)
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
