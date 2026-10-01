import PhotosUI
import SwiftUI

struct PhotoPickerButton: View {
  let label: String
  let onData: (Data) -> Void
  let onError: (String) -> Void

  init(
    _ label: String,
    onData: @escaping (Data) -> Void,
    onError: @escaping (String) -> Void,
  ) {
    self.label = label
    self.onData = onData
    self.onError = onError
  }

  @State private var selection: PhotosPickerItem?
  @State private var selectionId = UUID()

  var body: some View {
    PhotosPicker(selection: $selection, matching: .images) {
      Text(label)
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

#if DEBUG
#Preview {
  PhotoPickerButton("Pick") { _ in
    // on data
  } onError: { _ in
    // on error
  }
  .frame(width: 300)
}
#endif
