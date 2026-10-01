import SwiftUI

struct AlbumHeader: View {
  enum Size {
    case sm, lg
  }

  init(entry: AlbumEntry, size: Size = .sm) {
    self.init(
      title: entry.title,
      artist: entry.artist,
      size: size,
    )
  }

  init(title: String, artist: String, size: Size = .sm) {
    self.title = title
    self.artist = artist
    self.size = size
  }

  private let title: String
  private let artist: String
  private let size: Size

  private let styles: [Size: (Font.TextStyle, Font.TextStyle)] = [
    .sm: (.caption, .caption2),
    .lg: (.headline, .subheadline),
  ]

  var body: some View {
    let (titleStyle, artistStyle) = styles[size] ?? (.caption, .caption2)

    VStack(alignment: .leading, spacing: Spacing.xs) {
      Text(title)
        .font(.sligoilMicroBold(titleStyle))
        .foregroundStyle(.themePrimaryInverted)

      Text(artist)
        .font(.sligoilMicro(artistStyle))
        .foregroundStyle(.themeRed)
    }
  }
}
