import SwiftUI

struct InvertedShapeStyle<S: ShapeStyle>: ShapeStyle {
  let style: S

  func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
    var environment = environment
    environment.colorScheme =
      environment.colorScheme == .dark
      ? .light
      : .dark

    return style.resolve(in: environment)
  }
}

extension ShapeStyle {
  func inverted() -> InvertedShapeStyle<Self> {
    InvertedShapeStyle(style: self)
  }
}
