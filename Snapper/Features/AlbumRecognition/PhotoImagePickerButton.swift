import PhotosUI
import SwiftUI

struct PhotoImagePickerButton: View {
  let onImage: (Data) -> Void
  let onError: (String) -> Void

  @State private var selectedItem: PhotosPickerItem?
  @State private var loadGeneration = UUID()

  var body: some View {
    PhotosPicker(selection: $selectedItem, matching: .images) {
      Label("Choose Photo", systemImage: "photo")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.bordered)
    .controlSize(.large)
    .task(id: loadGeneration) {
      await loadSelectedPhoto()
    }
    .onChange(of: selectedItem) { _, item in
      guard item != nil else { return }
      loadGeneration = UUID()
    }
  }

  private func loadSelectedPhoto() async {
    guard let selectedItem else { return }

    do {
      guard let imageData = try await selectedItem.loadTransferable(type: Data.self) else {
        onError("Snapper could not load that photo. Choose another image or search manually.")
        return
      }
      try Task.checkCancellation()
      onImage(imageData)
      self.selectedItem = nil

    } catch is CancellationError {
      // A new photo selection replaced this load.

    } catch {
      onError(error.localizedDescription)
    }
  }
}
