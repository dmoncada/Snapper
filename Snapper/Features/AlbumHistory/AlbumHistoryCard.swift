import SwiftUI

struct AlbumHistoryCard: View {
  let album: Album

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      AlbumCover(url: album.coverImageUrl)
        .roundedOutline(lineWidth: LineWidth.sm)

      HStack(alignment: .center) {
        LabeledContent(album.artist, value: album.title)
          .frame(maxWidth: .infinity, alignment: .leading)
          .labeledContentStyle(.albumHeader)
          .controlSize(.small)
          .lineLimit(1)

        Spacer()

        Image(systemName: "heart.fill")
          .favoriteIconStyle(isFavorite: album.isFavorite)
          .opacity(album.isFavorite ? 1 : 0)

        Text(album.selectedAt.shortRelative(to: .now))
          .badgeStyle()
          .controlSize(.mini)
      }
      .padding(.vertical, Padding.sm)
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

private struct TestHistoryCard: View {
  let album: Album

  var body: some View {
    Button {
      album.isFavorite.toggle()
    } label: {
      AlbumHistoryCard(album: album)
        .contentShape(.rect)
    }
  }
}

#Preview("Single Column", traits: .withSampleData) {
  @Previewable @Query(sort: \Album.selectedAt) var albums: [Album]

  if albums.isEmpty {
    ProgressView()
  } else {
    ScrollView {
      WithColorSchemes {
        LazyVGrid(columns: [.init(.flexible())]) {
          TestHistoryCard(album: albums[0])
        }
        .padding()
      }
    }
  }
}

#Preview("Double Column", traits: .withSampleData) {
  @Previewable @Environment(\.dynamicTypeSize) var dynamicTypeSize

  @Previewable @Query(sort: \Album.selectedAt) var albums: [Album]

  var columns: [GridItem] {
    [
      dynamicTypeSize.isAccessibilitySize
        ? GridItem(.flexible(minimum: 160))
        : GridItem(.adaptive(minimum: 160))
    ]
  }

  if albums.count > 1 {
    ScrollView {
      WithColorSchemes {
        LazyVGrid(columns: columns) {
          TestHistoryCard(album: albums[0])
          TestHistoryCard(album: albums[1])
        }
        .padding()
      }
    }
  } else {
    ProgressView()
  }
}
#endif
