import SwiftUI

struct BadgeAppearance {
  let text: Color
  let line: Color
  let fill: Color
}

extension BadgeAppearance {
  static var `default`: Self {
    Self(
      text: .themePrimary,
      line: .themeSeparator,
      fill: .clear,
    )
  }

  static var highlighted: Self {
    Self(
      text: .themePrimaryActive,
      line: .clear,
      fill: .themeSurface1,
    )
  }
}
