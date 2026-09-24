#if os(iOS)
  import SwiftUI
  import UIKit

  struct CameraImagePicker: UIViewControllerRepresentable {
    let onCapture: (Data?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
      let picker = UIImagePickerController()
      picker.sourceType = .camera
      picker.cameraCaptureMode = .photo
      picker.allowsEditing = false
      picker.delegate = context.coordinator
      return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> CameraImagePickerCoordinator {
      CameraImagePickerCoordinator(onCapture: onCapture)
    }
  }
#endif
