import SwiftUI

struct AlbumHistoryCard: View {
  let album: Album

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      AlbumCover(url: album.coverImageUrl)
        .roundedOutline(lineWidth: LineWidth.sm)

      HStack(alignment: .center) {
        AlbumHeader(title: album.title, artist: album.artist)
          .frame(maxWidth: .infinity, alignment: .leading)
          // .minimumScaleFactor(0.75)
          .lineLimit(1)

        Spacer()

        Icon(systemName: "star.fill")
          .favoriteIconStyle(isFavorite: album.isFavorite)

        Text((album.selectedAt.shortRelative(to: .now)))
          .badgeStyle()
          .controlSize(.mini)
      }
      .frame(height: 40)
    }
  }
}

struct FavoriteIconStyle: ViewModifier {
  let isFavorite: Bool

  func body(content: Content) -> some View {
    content
      .foregroundStyle(.accent)
      .symbolEffect(
        .bounce.up,
        options: .speed(2),
        value: isFavorite,
      )
      .opacity(isFavorite ? 1 : 0)
  }
}

extension View {
  func favoriteIconStyle(isFavorite: Bool) -> some View {
    modifier(FavoriteIconStyle(isFavorite: isFavorite))
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

private struct TestHistoryCard: View {
  let album1: Album
  let album2: Album

  var body: some View {
    HStack {
      Button {
        album1.isFavorite.toggle()
      } label: {
        AlbumHistoryCard(album: album1)
          .contentShape(.rect)
      }

      Spacer()

      Button {
        album2.isFavorite.toggle()
      } label: {
        AlbumHistoryCard(album: album2)
          .contentShape(.rect)
      }
    }
    .buttonStyle(.plain)
  }
}

#Preview(traits: .withSampleData) {
  @Previewable @Query(sort: \Album.selectedAt) var albums: [Album]

  if albums.count > 1 {
    WithColorSchemes {
      TestHistoryCard(album1: albums[0], album2: albums[1])
        .padding()
    }
  } else {
    ProgressView()
  }
}
#endif
