import SwiftUI

nonisolated struct EdgeBorder: Shape {
  var width: CGFloat
  var edges: Edge.Set

  func path(in rect: CGRect) -> Path {
    var path = Path()

    if edges.contains(.top) {
      path.addRect(
        CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width)
      )
    }

    if edges.contains(.bottom) {
      path.addRect(
        CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width)
      )
    }

    if edges.contains(.leading) {
      path.addRect(
        CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height)
      )
    }

    if edges.contains(.trailing) {
      path.addRect(
        CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height)
      )
    }

    return path
  }
}

extension View {
  func edgeBorder<Style: ShapeStyle>(
    style: Style = Color.themePrimary,
    width: CGFloat = LineWidth.sm,
    edges: Edge.Set = .all,
  ) -> some View {
    overlay {
      EdgeBorder(width: width, edges: edges)
        .fill(style)
    }
  }
}

#if DEBUG
#Preview {
  Text("Hello")
    .padding()
    .edgeBorder(
      style: .tint,
      edges: [
        .top,
        .leading,
        .trailing,
      ],
    )
}
#endif
