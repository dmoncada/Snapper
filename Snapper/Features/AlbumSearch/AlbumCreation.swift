import SwiftData
import SwiftUI
import WidgetKit

struct AlbumCreation: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context

  @Environment(\.apiClient) private var apiClient
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
    do {
      album.selectedAt = .now
      album.locationStatusRaw = AlbumLocationStatus.pending.rawValue

      var genreCatalog = try GenreCatalog(context: context)
      genreCatalog.link(album)
      context.insert(album)

      try context.save()

      WidgetCenter.shared.reloadTimelines(ofKind: "SnapperWidget")

      locationCapture.resumePending(in: context)

      Task {
        do {
          let response = try await apiClient.fetchAlbumSummary(discogsId: album.discogsId)

          if let info = response.artist {
            album.artistInfo.set(info)
          }
          if let info = response.album {
            album.albumInfo.set(info)
          }

          try context.save()
        } catch {
          // Wikipedia is optional; the saved album remains available.
        }
      }

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
