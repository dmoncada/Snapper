import SwiftUI

nonisolated enum Padding {
  static let sm: CGFloat = 4
  static let md: CGFloat = 6
  static let lg: CGFloat = 8
  static let xl: CGFloat = 16
  static let xxl: CGFloat = 32
}

nonisolated enum Spacing {
  static let xs: CGFloat = 4
  static let sm: CGFloat = 8
  static let md: CGFloat = 16
  static let lg: CGFloat = 24
  static let xl: CGFloat = 32
}

nonisolated enum Radius {
  static let sm: CGFloat = 4
  static let md: CGFloat = 8
  static let lg: CGFloat = 16
  static let full: CGFloat = .infinity
}

nonisolated enum LineWidth {
  static let sm: CGFloat = 1
  static let md: CGFloat = 2
  static let lg: CGFloat = 4
}

enum Typography {
  static let albumDetailTitle: Font = .zillaSlab(.title).bold()
  static let albumDetailArtist: Font = .inter(.title2)

  static let albumRowTitle: Font = .zillaSlab(.caption).bold()
  static let albumRowArtist: Font = .inter(.caption2)

  static let sectionHeader: Font = .zillaSlab(.title3).bold()
  static let sectionFooter: Font = .zillaSlab(.footnote)

  static let buttonBody: Font = .inter(.body)
  static let labelBody: Font = .inter(.body)

  static func badge(for size: ControlSize) -> Font {
    .zillaSlab(.fromControlSize(size)).bold()
  }
}
