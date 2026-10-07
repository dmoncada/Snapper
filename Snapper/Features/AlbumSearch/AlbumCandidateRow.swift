import SwiftUI

struct AlbumCandidateRow: View {
  let candidate: AlbumCandidate

  var body: some View {
    HStack {
      AlbumThumbnail(url: candidate.thumbnailUrl)

      AlbumHeader(title: candidate.title, artist: candidate.artist)
        // .minimumScaleFactor(0.75)
        .lineLimit(1)

      Spacer()

      HStack(spacing: Spacing.xs) {
        if let year = candidate.year {
          Text(String(year))
            .badgeStyle()
        }

        if let format = candidate.formats.first {
          Text(format)
            .badgeStyle()
        }
      }
    }
    .frame(maxWidth: .infinity)
  }
}

private struct AlbumThumbnail: View {
  init(
    url: URL?,
    size: CGFloat = 64,
  ) {
    self.url = url
    self.size = size
  }

  private let url: URL?
  private let size: CGFloat

  var body: some View {
    CachedImage(url: url)
      .frame(width: size, height: size)
      .clipShape(.rect(cornerRadius: Radius.sm))
  }
}

#if DEBUG
import SwiftData

#Preview(traits: .withSampleData) {
  @Previewable @Query(sort: \AlbumEntry.selectedAt) var entries: [AlbumEntry]

  if entries.count > 1 {
    let entry1 = entries[0]
    let entry2 = entries[1]

    let album1 = entry1.toCandidate()
    let album2 = entry2.toCandidate()

    VStack(spacing: 0) {
      AlbumCandidateRow(candidate: album1)
        .padding()
        .frame(height: 150)
        .background(.themePrimary)
        .environment(\.colorScheme, .light)

      AlbumCandidateRow(candidate: album2)
        .padding()
        .frame(height: 150)
        .background(.themePrimary)
        .environment(\.colorScheme, .dark)
    }
  } else {
    ProgressView()
  }
}
#endif
