import SwiftUI

struct CameraShutterButton: View {
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
  @Previewable @State var alertItem: AlertDestination?

  CameraShutterButton {
    alertItem = .ok(
      "You snapped a photo!",
      title: "Photo snapped",
    )
  }
  .withAlertDestination($alertItem)
}
#endif
