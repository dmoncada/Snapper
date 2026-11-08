import SwiftUI

struct AlbumSelectableCard: View {
  let album: Album
  let isSelecting: Bool
  let isSelected: Bool

  var body: some View {
    ZStack {
      ConcentricRectangle(
        uniformTopCorners: .concentric,
        uniformBottomCorners: .fixed(0),
      )
      .fill(
        isSelecting && isSelected
          ? .accent.opacity(0.5)
          : .clear
      )

      VStack(alignment: .leading) {
        AlbumCover(url: album.coverImageUrl)
          .overlay {
            ConcentricRectangle(
              corners: .concentric,
              isUniform: true,
            )
            .stroke(
              .themeSeparatorOpaque,
              lineWidth: LineWidth.sm,
            )
          }
          .overlay(alignment: .topTrailing) {
            SelectionIndicator(
              isSelecting: isSelecting,
              isSelected: isSelected,
            )
            .padding(Padding.sm)
          }
          .overlay(alignment: .bottomTrailing) {
            AlbumMetadata(album: album)
              .padding(Padding.sm)
          }

        LabeledContent {
          Text(album.title)
            .font(Typography.albumRowTitle)
        } label: {
          Text(album.artist)
            .font(Typography.albumRowArtist)
        }
        .labeledContentStyle(.albumHeader)
        .lineLimit(1)
      }
      .padding(8)
    }
    .containerShape(.rect(cornerRadius: 16))
  }
}

private struct AlbumCover: View {
  let url: URL?

  private let shape = ConcentricRectangle(
    corners: .concentric,
    isUniform: true,
  )

  var body: some View {
    shape
      .fill(.themePlaceholder)
      .frame(maxWidth: .infinity)
      .aspectRatio(1, contentMode: .fit)
      .overlay {
        CachedImage(url: url)
          .aspectRatio(contentMode: .fill)
      }
      .clipShape(shape)
  }
}

private struct AlbumMetadata: View {
  let album: Album

  var body: some View {
    HStack(spacing: Spacing.xs) {
      Image(systemName: "heart.fill")
        .favoriteIconStyle(isFavorite: album.isFavorite)
        .foregroundStyle(.themeSurface1)
        .opacity(album.isFavorite ? 1 : 0)

      if album.location != nil {
        Image(systemName: "location.circle.fill")
          .symbolRenderingMode(.palette)
          .foregroundStyle(
            .themePrimaryActive,
            .themeSurface1,
          )
      }

      Text("\(album.selectedAt.shortRelative(to: .now)) ago")
        .badgeStyle(appearance: .highlighted)
        .controlSize(.mini)
    }
  }
}

private struct SelectionIndicator: View {
  let isSelecting: Bool
  let isSelected: Bool

  var body: some View {
    if isSelecting {
      if isSelected {
        Image(systemName: "checkmark.circle.fill")
          .transition(.symbolEffect(.drawOn, options: .speed(0.75)))
          .symbolRenderingMode(.palette)
          .foregroundStyle(
            .themePrimaryInverted,
            .selection,
          )
      } else {
        Image(systemName: "circle")
          .foregroundStyle(.themeSeparator)
      }
    }
  }
}

#if DEBUG
import SwiftData

private struct TestSelectableGrid: View {
  @Query(descriptor) var albums: [Album]

  static let descriptor = FetchDescriptor<Album>(
    predicate: #Predicate { album in
      album.artist.starts(with: "Natalia")
    },
    sortBy: [
      SortDescriptor(\Album.selectedAt, order: .reverse)
    ],
  )

  @State private var selection = Set<Album.ID>()

  var body: some View {
    NavigationStack {
      SelectableGrid(
        albums,
        selection: $selection,
        isSelecting: true,
        onOpen: { _ in },
      ) { album, isSelected in
        AlbumSelectableCard(
          album: album,
          isSelecting: true,
          isSelected: isSelected,
        )
      }
      .navigationTitle("Albums")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Clear") {
            selection.removeAll()
          }
          .disabled(selection.isEmpty)
        }
      }
      .withFullBackground()
    }
  }
}

#Preview(traits: .withSampleData) {
  TestSelectableGrid()
}
#endif
