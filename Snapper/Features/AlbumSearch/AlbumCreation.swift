import SwiftData
import SwiftUI

struct AlbumCreation: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context

  let entry: AlbumEntry

  var body: some View {
    NavigationStack {
      AlbumDetailView(entry: entry)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button(role: .cancel) {
              dismiss()
            }
          }

          ToolbarItem(placement: .topBarTrailing) {
            Button(role: .confirm) {
              print("Added to history")
              context.insert(entry)
              dismiss()
            }
          }
        }
    }
  }
}
