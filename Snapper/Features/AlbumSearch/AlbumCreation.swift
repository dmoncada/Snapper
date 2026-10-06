import SwiftData
import SwiftUI
import WidgetKit

struct AlbumCreation: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  @Environment(AlbumLocationCaptureCoordinator.self) private var locationCapture

  let entry: AlbumEntry
  var onSave: (() -> Void)?
  var onShowAllResults: (() -> Void)?

  @State private var saveContext: ModelContext?
  @State private var alertItem: AlertDestination?

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

          /*
          if let onShowAllResults {
            ToolbarItem(placement: .bottomBar) {
              Button("Show all results", systemImage: "list.bullet") {
                saveContext?.rollback()
                onShowAllResults()
              }
            }
          }
          */

          ToolbarItem(placement: .topBarTrailing) {
            Button(role: .confirm) {
              save()
            }
          }
        }
    }
    .interactiveDismissDisabled()
    .withAlertDestination($alertItem)
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
      WidgetCenter.shared.reloadTimelines(ofKind: "SnapperWidget")
      locationCapture.resumePending(in: context)
      onSave?()
      dismiss()
    } catch {
      alertItem = AlertDestination(
        title: "Could not add album",
        message: "The album could not be saved: \(error.localizedDescription)",
        primary: .init(title: "Retry", action: save),
        secondary: .cancel,
      )
    }
  }
}
