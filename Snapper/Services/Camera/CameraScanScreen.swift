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

          TriggerButton(action: requestPhoto)
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
    do {
      try await camera.start()
      try Task.checkCancellation()
      isReady = true

      let barcodes = await camera.barcodes()
      for await barcode in barcodes {
        guard !isCapturing, !isCompleted else { continue }
        isCompleted = true

        await camera.stop()
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
    if isCompleted { return }
    isCompleted = true

    Task {
      await camera.stop()
      dismiss()
    }
  }

  @MainActor
  private func requestPhoto() {
    if isCompleted { return }
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
      if isCompleted { return }
      isCompleted = true

      await camera.stop()
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

private struct TriggerButton: View {
  let action: () -> Void
  let size: CGFloat

  init(
    action: @escaping () -> Void,
    size: CGFloat = 100,
  ) {
    self.action = action
    self.size = size
  }

  var body: some View {
    Button {
      action()
    } label: {
      Image(systemName: "camera.circle.fill")
        .resizable()
        .scaledToFit()
        .frame(width: size, height: size)
    }
    .buttonBorderShape(.circle)
  }
}

#if DEBUG
#Preview {
  @Previewable @State var router = Router()

  TriggerButton {
    router.alertItem = AlertDestination(
      title: "Photo snapped",
      message: "You snapped a photo!",
      primary: .init(title: "OK"),
    )
  }
  .withAlertDestination($router.alertItem)
  .environment(router)
}
#endif
