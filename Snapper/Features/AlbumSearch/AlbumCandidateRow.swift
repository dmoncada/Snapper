import SwiftUI

struct AlbumCandidateRow: View {
  let album: Album

  private let size: CGFloat = 64

  var body: some View {
    HStack {
      AlbumThumbnail(url: album.thumbnailUrl)

      VStack(alignment: .leading, spacing: 0) {
        Text(album.title)
          .font(Typography.albumRow.title)
          .foregroundStyle(.themePrimary)

        Text(album.artist)
          .font(Typography.albumRow.artist)
          .foregroundStyle(.accent)
      }
      .frame(
        maxWidth: .infinity,
        alignment: .leading,
      )
      .lineLimit(1)

      Spacer()

      FlowLayout(alignment: .trailing) {
        if let country = album.countryCode {
          Text(country)
            .badgeStyle()
        }

        if let year = album.year?.description {
          Text(year)
            .badgeStyle()
        }

        if let format = album.mediaFormats.first {
          Text(format.resource)
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
      .roundedOutline(lineWidth: LineWidth.sm)
  }
}

extension Album {
  var mediaFormats: [AlbumFormat] {
    format.compactMap { AlbumFormat(rawValue: $0.lowercased()) }
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
