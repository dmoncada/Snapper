import SwiftUI

struct CameraAlbumScanScreen: View {
  let onPhoto: @MainActor (Data) -> Void

  @Environment(\.dismiss) private var dismiss

  @State private var model = AlbumScanFlowModel()
  @State private var camera = PhotoCaptureService()
  @State private var alertItem: AlertDestination?

  @State private var isReady = false
  @State private var isCapturing = false
  @State private var isCompleted = false
  @State private var isClosing = false

  var body: some View {
    NavigationStack {
      ZStack {
        Color.black
          .ignoresSafeArea()

        CameraPreview(source: camera.previewSource)
          .ignoresSafeArea()

        VStack {
          Spacer()

          Text("Point at a barcode or snap a photo")
            .padding(.bottom, Spacing.lg)
            .foregroundStyle(.white)

          CameraShutterButton(action: requestPhoto)
            .foregroundStyle(.white)
            .disabled(
              isReady == false
                || isCapturing
                || isCompleted
            )
        }
      }
      .navigationToolbar(title: "Snap a photo") {
        requestClose()
      }
      .withAlertDestination($alertItem)
    }
    .overlay {
      AlbumScanStatusView(model: model)
    }
    .sheet(isPresented: $model.isShowingAlbum, onDismiss: sheetDismissed) {
      if let entry = model.selectedEntry {
        AlbumCreation(
          entry: entry,
          onSave: model.markSaved,
          onShowAllResults: model.showAllResults,
        )
      }

      /*
      AlbumScanSelectionSheet(model: model)
        .presentationDetents([.large])
        .interactiveDismissDisabled()
       */
    }
    .task(id: isClosing) {
      guard isClosing else { return }
      await camera.stop()
      dismiss()
    }
    .task(id: model.lookupGeneration) {
      await model.lookup()
    }
    .task(id: model.scanGeneration) {
      await scan()
    }
    .onDisappear {
      Task {
        await camera.stop()
      }
    }
  }

  @MainActor
  private func scan() async {
    if isClosing { return }
    isCompleted = false
    isReady = false

    do {
      try await camera.start()
      try Task.checkCancellation()

      if isClosing {
        await camera.stop()
        return
      }

      isReady = true

      let barcodes = await camera.barcodes()

      for await barcode in barcodes {
        try Task.checkCancellation()

        guard !isCapturing, !isCompleted, !isClosing else { continue }
        isCompleted = true

        model.accept(barcode)
        break
      }
    } catch is CancellationError {
      await camera.stop()
    } catch {
      alertItem = AlertDestination(
        title: "Error",
        message: "Camera error: \(error.localizedDescription)",
        primary: .init(title: "Ok"),
      )
    }
  }

  @MainActor
  private func requestClose() {
    if isClosing { return }

    isClosing = true
    isCompleted = true

    model.close()
  }

  @MainActor
  private func requestPhoto() {
    guard isReady, !isCapturing, !isCompleted, !isClosing else { return }
    isCapturing = true

    Task {
      await takePhoto()
    }
  }

  @MainActor
  private func takePhoto() async {
    defer { isCapturing = false }

    do {
      let data = try await camera.takePhoto()
      guard !isCompleted, !isClosing else { return }
      isCompleted = true
      model.close()

      await camera.stop()

      if isClosing { return }
      onPhoto(data)
    } catch {
      alertItem = AlertDestination(
        title: "Error",
        message: "Camera error: \(error.localizedDescription)",
        primary: .init(title: "OK"),
      )
    }
  }

  private func sheetDismissed() {
    if model.didSave {
      requestClose()
    } else {
      model.scanAgain()
    }
  }
}
