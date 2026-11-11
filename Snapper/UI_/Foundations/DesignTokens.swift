import SwiftUI

nonisolated enum Padding {
  static let sm: CGFloat = 4
  static let md: CGFloat = 6
  static let lg: CGFloat = 8
  static let xl: CGFloat = 16
  static let xxl: CGFloat = 24
  static let xxxl: CGFloat = 32
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
  struct AlbumDetail {
    let title: Font = .zillaSlab(.title).bold()
    let artist: Font = .gillSans(.title2)
  }

  struct AlbumRow {
    let title: Font = .zillaSlab(.headline).bold()
    let artist: Font = .gillSans(.subheadline)
  }

  struct Section {
    let header: Font = .zillaSlab(.title3).bold()
    let footer: Font = .zillaSlab(.footnote)
  }

  struct Badge {
    func `for`(_ size: ControlSize) -> Font {
      .zillaSlab(.fromControlSize(size)).bold()
    }
  }

  static let albumDetail = AlbumDetail()
  static let albumRow = AlbumRow()
  static let section = Section()
  static let badge = Badge()

  static let buttonBody: Font = .gillSans(.title2)

  static let labelBody: Font = .gillSans(.body)
}
