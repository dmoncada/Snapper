import SwiftUI

struct AlbumCandidateRow: View {
  let album: Album

  private let size: CGFloat = 64

  var body: some View {
    HStack {
      AlbumThumbnail(url: album.thumbnailUrl)

      LabeledContent {
        Text(album.title)
          .font(Typography.albumRow.title)
      } label: {
        Text(album.artist)
          .font(Typography.albumRow.artist)
      }
      .frame(
        maxWidth: .infinity,
        alignment: .leading,
      )
      .labeledContentStyle(.albumHeader)
      .lineLimit(1)

      Spacer()

      FlowLayout(alignment: .trailing) {
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
      .frame(maxWidth: 120)
      .controlSize(.mini)
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
      .scaledToFill()
      .frame(width: size, height: size)
      .roundedOutline(radius: Radius.sm, lineWidth: 1)
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
      }
      .padding()
    }
  } else {
    ProgressView()
  }
}
#endif
