#if os(iOS)
  import UIKit

  @MainActor
  final class CameraImagePickerCoordinator: NSObject, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
  {
    private let onCapture: (Data?) -> Void

    init(onCapture: @escaping (Data?) -> Void) {
      self.onCapture = onCapture
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      let imageData = (info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.95)
      onCapture(imageData)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      onCapture(nil)
    }
  }
#endif
