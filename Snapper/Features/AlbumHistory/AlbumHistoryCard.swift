import SwiftUI

struct AlbumHistoryCard: View {
  let entry: AlbumEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      AlbumCover(url: URL(string: entry.coverImageUrlString ?? ""))
        .roundedOutline(lineWidth: 1)

      HStack(alignment: .center) {
        AlbumHeader(entry: entry)
          .frame(maxWidth: .infinity, alignment: .leading)
          .minimumScaleFactor(0.75)
          .lineLimit(1)

        Spacer()

        if entry.isFavorited {
          Image(systemName: "star.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundStyle(.accent)
        }

        Text((entry.selectedAt.shortRelative(to: .now)))
          .padding(Padding.md)
          .font(.sligoilMicroMedium(.caption2))
          .foregroundStyle(.themePrimaryInverted)
          .roundedOutline(lineWidth: 1, color: .themePrimaryInverted)
      }
      .frame(height: 40)
    }
  }
}

private struct AlbumCover: View {
  let url: URL?

  var body: some View {
    Color.clear
      .frame(maxWidth: .infinity)
      .aspectRatio(1, contentMode: .fit)
      .overlay {
        CachedImage(url: url)
          .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
          )
          .clipped()
      }
  }
}

#if DEBUG
import SwiftData

#Preview(traits: .withSampleData) {
  @Previewable @Query(sort: \AlbumEntry.selectedAt) var entries: [AlbumEntry]

  if entries.count > 3 {
    let sizes: [(CGFloat, CGFloat)] = [
      (300, 32),
      (200, 24),
      (100, 16),
    ]

    let tuples = Array(zip(entries, sizes))

    ScrollView(.vertical) {
      ForEach(tuples.enumerated(), id: \.offset) { _, tuple in
        let (entry, (card, icon)) = tuple

        AlbumHistoryCard(entry: entry)
          .frame(width: card)
          .overlay(alignment: .topTrailing) {
            SelectionIndicator(
              isSelected: true,
              size: icon,
            )
          }
      }
    }
    .onAppear {
      for i in 0 ..< 3 {
        let entry = entries[i]
        entry.isFavorited = true
      }
    }
    .fullBackground(.gray.opacity(0.5))
  } else {
    ProgressView()
  }
}
#endif
