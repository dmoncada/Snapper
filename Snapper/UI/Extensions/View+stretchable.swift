import SwiftUI

// Take from: https://livsycode.com/swiftui/stretchable-header-in-swiftui-for-vertical-and-horizontal-scrollview/
extension View {
  func stretchable(
    axis: Axis = .vertical,
    uniform: Bool = true
  ) -> some View {

    visualEffect { effect, geometry in
      let frame = geometry.frame(in: .scrollView)

      let offset: CGFloat
      let length: CGFloat

      switch axis {
      case .vertical:
        offset = frame.minY
        length = geometry.size.height

      case .horizontal:
        offset = frame.minX
        length = geometry.size.width
      }

      let scale = (length + max(0, offset)) / max(length, 0.0001)
      let anchor: UnitPoint = axis == .vertical ? .bottom : .trailing

      if uniform {
        return effect.scaleEffect(
          x: scale,
          y: scale,
          anchor: anchor
        )
      } else {
        return effect.scaleEffect(
          x: axis == .horizontal ? scale : 1,
          y: axis == .vertical ? scale : 1,
          anchor: anchor
        )
      }
    }
  }

}
