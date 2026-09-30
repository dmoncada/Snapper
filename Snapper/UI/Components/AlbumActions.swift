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

private struct DeleteAlertModifier: ViewModifier {
  @Binding var pendingDelete: AlbumEntry?

  let onDelete: (AlbumEntry) -> Void

  private var isPresented: Binding<Bool> {
    Binding(
      get: { pendingDelete != nil },
      set: { if !$0 { pendingDelete = nil } }
    )
  }

  func body(content: Content) -> some View {
    content.alert(
      "Delete Album?",
      isPresented: isPresented,
      presenting: pendingDelete
    ) { entry in

      Button("Cancel", role: .cancel) {
        pendingDelete = nil
      }

      Button("Delete", role: .destructive) {
        pendingDelete = nil
        onDelete(entry)
      }

    } message: { entry in
      Text("Are you sure you want to delete \"\(entry.title)\" from your history?")
    }
  }
}

extension View {
  func deleteAlert(
    pendingDelete: Binding<AlbumEntry?>,
    onDelete: @escaping (AlbumEntry) -> Void
  ) -> some View {
    modifier(
      DeleteAlertModifier(
        pendingDelete: pendingDelete,
        onDelete: onDelete
      )
    )
  }
}
