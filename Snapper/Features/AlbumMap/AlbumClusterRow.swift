import SwiftUI

struct AlbumClusterRow: View {
  let album: Album

  private let size: CGFloat = 48

  var body: some View {
    HStack(spacing: Spacing.sm) {
      CachedImage(url: album.thumbnailUrl)
        .scaledToFill()
        .frame(width: size, height: size)
        .roundedOutline(lineStyle: .clear)

      VStack(alignment: .leading, spacing: Spacing.xs) {
        Text(album.title)
          .font(Typography.albumRow.title)
          .foregroundStyle(.themePrimary)
          .lineLimit(1)

        Text(album.artist)
          .font(Typography.albumRow.artist)
          .foregroundStyle(.accent)
          .lineLimit(1)

        HStack(spacing: Spacing.xs) {
          TimelineView(.periodic(from: album.selectedAt, by: 60)) { timeline in
            if Calendar.current.isDate(album.selectedAt, inSameDayAs: timeline.date) {
              Text(
                album.selectedAt,
                format: Date.RelativeFormatStyle(
                  allowedFields: [.hour, .minute, .second],
                  unitsStyle: .narrow,
                ),
              )
            } else {
              Text(album.selectedAt, format: .dateTime.hour().minute())
            }
          }
          .font(.inter(.caption))
          .foregroundStyle(.themeSecondary)

          if album.isFavorite {
            Image(systemName: "heart.fill")
              .foregroundStyle(.accent)
              .imageScale(.small)
              .scaleEffect(0.75)
          }
        }
      }

      Spacer()

      Image(systemName: "chevron.right")
        .foregroundStyle(.themeSecondary)
    }
  }
}

#if DEBUG
import SwiftData

#Preview(traits: .withSearchContext) {
  @Previewable @Query(sort: \Album.selectedAt, order: .reverse) var albums: [Album]

  if let album = albums.first {
    WithColorSchemes {
      AlbumClusterRow(album: album)
        .padding()
        .task {
          album.isFavorite = true
        }
    }
  } else {
    ProgressView()
  }
}
#endif
