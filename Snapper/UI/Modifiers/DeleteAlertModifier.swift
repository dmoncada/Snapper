import SwiftUI

private struct DeleteAlertModifier: ViewModifier {
  @Binding var pendingDelete: AlbumEntry?

  let onDelete: (AlbumEntry) -> Void

  func body(content: Content) -> some View {
    content
      .alert(
        "Delete Album?",
        isPresented: .isPresented(for: $pendingDelete),
        presenting: pendingDelete,
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
    for pendingDelete: Binding<AlbumEntry?>,
    onDelete: @escaping (AlbumEntry) -> Void,
  ) -> some View {
    modifier(
      DeleteAlertModifier(
        pendingDelete: pendingDelete,
        onDelete: onDelete,
      )
    )
  }
}

#if DEBUG
import SwiftData

#Preview(traits: .withSampleData) {
  @Previewable @Query var entries: [AlbumEntry]
  @Previewable @State var pendingDelete: AlbumEntry?

  if let entry = entries.first {
    Button("Delete album") {
      pendingDelete = entry
    }
    .deleteAlert(for: $pendingDelete) { _ in
      print("Album deleted")
    }
  } else {
    ProgressView()
  }
}
#endif
