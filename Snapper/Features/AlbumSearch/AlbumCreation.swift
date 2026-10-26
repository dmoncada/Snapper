import SwiftData
import SwiftUI
import WidgetKit

struct AlbumCreation: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  @Environment(AlbumLocationCaptureCoordinator.self) private var locationCapture

  let album: Album
  var onSave: (() -> Void)?

  @State private var alertItem: AlertDestination?

  var body: some View {
    NavigationStack {
      AlbumDetailView(album: album, showMetadata: false)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button(role: .cancel) {
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
    .withAlertDestination($alertItem)
  }

  private func save() {
    album.selectedAt = .now
    album.locationStatusRaw = AlbumLocationStatus.pending.rawValue

    context.insert(album)

    do {
      try context.save()

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
