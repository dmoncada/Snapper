import SwiftData
import SwiftUI

struct AlbumCreation: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  @Environment(AlbumLocationCaptureCoordinator.self) private var locationCapture

  let entry: AlbumEntry

  @State private var saveContext: ModelContext?
  @State private var saveError: String?
  @State private var showsSaveError = false

  var body: some View {
    NavigationStack {
      AlbumDetailView(entry: entry, showMetadata: false)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button(role: .cancel) {
              saveContext?.rollback()
              dismiss()
            }
          }

          ToolbarItem(placement: .topBarTrailing) {
            Button(role: .confirm) {
              save()
            }
          }
        }
    }
    .interactiveDismissDisabled()
    .alert("Couldn't add album", isPresented: $showsSaveError) {
      Button(role: .cancel) {}
      Button("Retry") { save() }
    } message: {
      Text(saveError ?? "The album could not be saved.")
    }
  }

  private func save() {
    if saveContext == nil {
      let newContext = ModelContext(context.container)
      newContext.autosaveEnabled = false
      newContext.insert(entry)
      saveContext = newContext
    }

    entry.selectedAt = .now
    entry.locationCaptureStatusRaw = AlbumLocationStatus.pending.rawValue

    guard let saveContext else { return }

    do {
      try saveContext.save()
      locationCapture.resumePending(in: context)
      dismiss()
    } catch {
      saveError = error.localizedDescription
      showsSaveError = true
    }
  }
}
