#if os(iOS)
  import AVFoundation
  import SwiftUI
  import UIKit

  struct CameraCaptureButton: View {
    let onImage: (Data) -> Void

    @State private var cameraRequestToken: UUID?
    @State private var handledCameraRequestToken: UUID?
    @State private var isPresentingCamera = false
    @State private var isShowingCameraAlert = false
    @State private var cameraAlertTitle = ""
    @State private var cameraAlertMessage = ""
    @State private var cameraPermissionWasDenied = false

    var body: some View {
      Button("Scan Record", systemImage: "camera", action: requestCamera)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .task(id: cameraRequestToken) {
          guard
            let cameraRequestToken,
            cameraRequestToken != handledCameraRequestToken
          else { return }

          handledCameraRequestToken = cameraRequestToken
          await checkCameraAccess()
        }
        .fullScreenCover(isPresented: $isPresentingCamera) {
          CameraImagePicker { imageData in
            isPresentingCamera = false
            if let imageData {
              onImage(imageData)
            }
          }
          .ignoresSafeArea()
        }
        .alert(cameraAlertTitle, isPresented: $isShowingCameraAlert) {
          if cameraPermissionWasDenied {
            Button("Open Settings", action: openSettings)
          }
          Button("OK", role: .cancel) {}
        } message: {
          Text(cameraAlertMessage)
        }
    }

    private func requestCamera() {
      cameraRequestToken = UUID()
    }

    private func checkCameraAccess() async {
      guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
        presentCameraAlert(
          title: "Camera Unavailable",
          message: "This device can’t capture photos. Choose a photo or search manually.",
          permissionWasDenied: false)
        return
      }

      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
        isPresentingCamera = true

      case .notDetermined:
        let isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        if Task.isCancelled { return }
        if isAuthorized {
          isPresentingCamera = true
        } else {
          showPermissionAlert()
        }

      case .denied, .restricted:
        showPermissionAlert()

      @unknown default:
        showPermissionAlert()
      }
    }

    private func showPermissionAlert() {
      presentCameraAlert(
        title: "Camera Access Needed",
        message:
          "Allow camera access in Settings to scan an album. You can also choose a photo or search manually.",
        permissionWasDenied: true)
    }

    private func presentCameraAlert(title: String, message: String, permissionWasDenied: Bool) {
      cameraAlertTitle = title
      cameraAlertMessage = message
      cameraPermissionWasDenied = permissionWasDenied
      isShowingCameraAlert = true
    }

    private func openSettings() {
      guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
      UIApplication.shared.open(settingsUrl)
    }
  }
#endif
