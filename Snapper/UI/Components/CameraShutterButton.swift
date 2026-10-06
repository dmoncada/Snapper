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
  @Previewable @State var router = Router()

  CameraShutterButton {
    router.alertItem = AlertDestination(
      title: "Photo snapped",
      message: "You snapped a photo!",
      primary: .init(title: "Ok"),
    )
  }
  .withAlertDestination($router.alertItem)
  .environment(router)
}
#endif
