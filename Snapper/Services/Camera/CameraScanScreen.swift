import SwiftUI

struct CameraScanScreen: View {
  let onBarcode: @MainActor (String) -> Void
  let onPhoto: @MainActor (Data) -> Void

  @Environment(\.dismiss) private var dismiss

  @State private var camera = PhotoCaptureService()
  @State private var cameraError: Error?

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
            .foregroundStyle(.white)

          TriggerButton(action: requestPhoto)
            .foregroundStyle(.white)
            .disabled(
              isReady == false
                || isCapturing
                || isCompleted
            )
        }
        .padding()
      }
      .navigationTitle("Snap a photo")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(role: .close) {
            requestClose()
          }
        }
      }
      .errorAlert(for: $cameraError)
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
      cameraError = error
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
      cameraError = error
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

struct ErrorAlertModifier: ViewModifier {
  @Binding var error: Error?

  func body(content: Content) -> some View {
    if #available(iOS 27.0, *) {
      content
        .alert(error: $error) { _ in
          Button(role: .cancel) {}
          Button("Settings", role: .confirm) {
            error = nil
          }
        } message: { error in
          Text(error.localizedDescription)
        }
    } else {
      content
        .alert(
          "Error",
          isPresented: Binding(
            get: { error != nil },
            set: { if !$0 { error = nil } },
          ),
        ) {
          Button(role: .cancel) {}
          Button("Settings", role: .confirm) {
            error = nil
          }
        } message: {
          Text(error?.localizedDescription ?? "")
        }
    }
  }
}

extension View {
  func errorAlert(for error: Binding<Error?>) -> some View {
    modifier(ErrorAlertModifier(error: error))
  }
}

#Preview {
  @Previewable @State var error: Error?

  TriggerButton {
    error = URLError(.badURL)
  }
  .errorAlert(for: $error)
}
