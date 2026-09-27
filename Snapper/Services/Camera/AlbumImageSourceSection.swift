import SwiftUI

struct AlbumImageSourceSection: View {
  let onImage: (Data) -> Void
  let onError: (String) -> Void
  let isDisabled: Bool

  var body: some View {
    Section("Recognize from an image") {
      #if os(iOS)
        HStack {
          CameraCaptureButton(onImage: onImage)
            .frame(maxWidth: .infinity)

          PhotoImagePickerButton(onImage: onImage, onError: onError)
            .frame(maxWidth: .infinity)
        }
        .disabled(isDisabled)
      #else
        PhotoImagePickerButton(onImage: onImage, onError: onError)
          .disabled(isDisabled)
      #endif
    }
  }
}
