import SwiftUI

struct AlbumCandidateRow: View {
  let album: Album

  private let size: CGFloat = 64

  var body: some View {
    HStack {
      AlbumThumbnail(url: album.thumbnailUrl)

      AlbumHeader(title: album.title, artist: album.artist)
        // .minimumScaleFactor(0.75)
        .lineLimit(1)

      Spacer()

      HStack(spacing: Spacing.xs) {
        if let country = album.countryCode {
          Text(country)
            .badgeStyle()
        }

        if let year = album.year {
          Text(String(year))
            .badgeStyle()
        }

        if let format = album.mediaFormats.first {
          Text(format.description)
            .badgeStyle()
        }
      }
    }
  }
}

private struct AlbumThumbnail: View {
  let url: URL?
  let size: CGFloat

  init(
    url: URL?,
    size: CGFloat = 64,
  ) {
    self.url = url
    self.size = size
  }

  var body: some View {
    CachedImage(url: url)
      .frame(width: size, height: size)
      .clipShape(.rect(cornerRadius: Radius.sm))
  }
}

enum MediaFormat: String, CaseIterable {
  case vinyl
  case cd
  case cassette
}

extension MediaFormat: CustomStringConvertible {
  var description: String {
    switch self {
    case .vinyl: "Vinyl"
    case .cd: "CD"
    case .cassette: "Cassette"
    }
  }
}

extension Album {
  var mediaFormats: [MediaFormat] {
    format.compactMap { MediaFormat(rawValue: $0.lowercased()) }
  }
}

#if DEBUG
import SwiftData

#Preview(traits: .withSampleData) {
  @Previewable @Query(sort: \Album.selectedAt, order: .reverse) var albums: [Album]

  if let album = albums.first {
    WithColorSchemes {
      Button {
        // No-op.
      } label: {
        AlbumCandidateRow(album: album)
          .border(.red)
      }
      .padding()
    }
  } else {
    ProgressView()
  }
}
#endif
