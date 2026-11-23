import SwiftUI

@available(iOS 27.1, *)
struct HingeAwareView<
  Primary: View,
  Fallback: View,
>: View {
  @State private var isLandscape = false
  @State private var hingeStatus: DeviceHinge.Status?

  @ViewBuilder let primary: () -> Primary
  @ViewBuilder let fallback: () -> Fallback

  var body: some View {
    let isHingeOpen = hingeStatus == .partiallyOpen || hingeStatus == .fullyOpen

    ZStack {
      if isHingeOpen, isLandscape {
        primary()
      } else {
        fallback()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onGeometryChange(for: Bool.self) { geometry in
      geometry.size.width > geometry.size.height
    } action: { isLandscape in
      self.isLandscape = isLandscape
    }
    .onHingeChange { _, context in
      hingeStatus = context.hinge?.status
    }
  }
}
