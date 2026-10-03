import SwiftUI

struct AlbumCandidateRow: View {
  let candidate: AlbumCandidate

  var body: some View {
    HStack {
      AlbumThumbnail(url: candidate.thumbnailUrl)

      AlbumHeader(title: candidate.title, artist: candidate.artist)
        .minimumScaleFactor(0.5)
        .lineLimit(1)

      Spacer()

      HStack(spacing: Spacing.xs) {
        if let year = candidate.year {
          Text(String(year))
            .padding(Padding.md)
            .roundedOutline(radius: Radius.md, lineWidth: 1)
        }

        if let format = candidate.formats.first {
          Text(format)
            .padding(Padding.md)
            .roundedOutline(radius: Radius.md, lineWidth: 1, color: .themePrimaryInverted)
        }
      }
      .font(.sligoilMicroMedium(.caption2))
      .foregroundStyle(.themePrimaryInverted)
    }
    .frame(maxWidth: .infinity)
  }
}

struct AlbumThumbnail: View {
  let url: URL?

  var body: some View {
    CachedImage(url: url)
      .frame(width: 64, height: 64)
      .clipShape(.rect(cornerRadius: Radius.sm))
  }
}

#if DEBUG
import SwiftData

#Preview(traits: .withSampleData) {
  @Previewable @Query var entries: [AlbumEntry]

  if let entry = entries.first {
    let album = entry.toCandidate()

    VStack(spacing: 0) {
      AlbumCandidateRow(candidate: album)
        .padding()
        .frame(height: 150)
        .background(.themePrimary)
        .colorScheme(.light)

      AlbumCandidateRow(candidate: album)
        .padding()
        .frame(height: 150)
        .background(.themePrimary)
        .colorScheme(.dark)
    }
  } else {
    ProgressView()
  }
}
#endif
