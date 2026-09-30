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
        .tint(.themeYellow)

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

  private var presented: Binding<Bool> {
    Binding(
      get: { pendingDelete != nil },
      set: { if !$0 { pendingDelete = nil } }
    )
  }

  func body(content: Content) -> some View {
    content
      .alert("Delete Album?", isPresented: presented) {
        Button("Cancel", role: .cancel) {
          pendingDelete = nil
        }

        Button("Delete", role: .destructive) {
          guard let entry = pendingDelete else { return }

          onDelete(entry)
          pendingDelete = nil
        }
      } message: {
        if let entry = pendingDelete {
          Text(
            "Are you sure you want to delete \"\(entry.title)\" from your history?"
          )
        }
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
