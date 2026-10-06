import SwiftUI

struct CameraScanScreen: View {
  let onBarcode: @MainActor (String) -> Void
  let onPhoto: @MainActor (Data) -> Void

  @Environment(\.dismiss) private var dismiss

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
    .task {
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
    guard !isClosing else { return }
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

        await camera.stop()

        if isClosing { return }
        onBarcode(barcode)
        break
      }
    } catch is CancellationError {
      await camera.stop()
    } catch {
      alertItem = AlertDestination(
        title: "Error",
        message: "Camera error: \(error.localizedDescription)",
        primary: .init(title: "OK"),
      )
    }
  }

  @MainActor
  private func requestClose() {
    if isClosing { return }
    isClosing = true
    isCompleted = true

    Task {
      await camera.stop()
      dismiss()
    }
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
}
