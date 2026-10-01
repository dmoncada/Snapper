import PhotosUI
import SwiftUI

struct PhotoPickerButton: View {
  let onData: (Data) -> Void
  let onError: (String) -> Void

  @State private var selection: PhotosPickerItem?
  @State private var selectionId = UUID()

  var body: some View {
    PhotosPicker(selection: $selection, matching: .images) {
      Text("Pick")
    }
    .buttonStyle(.large)
    .task(id: selectionId) {
      await load()
    }
    .onChange(of: selection) { _, item in
      if item == nil { return }
      selectionId = UUID()
    }
  }

  private func load() async {
    guard let selection else { return }

    do {
      guard let data = try await selection.loadTransferable(type: Data.self) else {
        onError("Failed to load data.")
        return
      }

      try Task.checkCancellation()

      self.selection = nil
      onData(data)
    } catch is CancellationError {
      // A new photo selection replaced this load.
    } catch {
      onError(error.localizedDescription)
    }
  }
}

#Preview {
  PhotoPickerButton { _ in
    // on data
  } onError: { _ in
    // on error
  }
  .frame(width: 300)
}
