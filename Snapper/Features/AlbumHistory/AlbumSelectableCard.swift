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
            .font(Typography.albumRow.title)
        } label: {
          Text(album.artist)
            .font(Typography.albumRow.artist)
        }
        .labeledContentStyle(.albumHeader)
        .lineLimit(1)
      }
      .padding(4)
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
  @Environment(\.dateTimeProvider) private var provider

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

      Text(
        album.selectedAt,
        format: .relative(
          presentation: .numeric,
          unitsStyle: .narrow,
        ),
      )
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
  @Query(sort: \Album.selectedAt, order: .reverse) var albums: [Album]

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
      .task {
        let offsets: [(value: Int, unit: Calendar.Component)] = [
          (1, .minute),
          (1, .hour),
          (1, .day),
          (1, .weekOfYear),
          (1, .month),
          (1, .year),
        ]

        guard albums.count >= offsets.count else { return }

        for (album, offset) in albums.withOffsets(offsets, stride: 1) {
          album.selectedAt = album.selectedAt.subtract(
            offset.value,
            unit: offset.unit,
          )
        }
      }
    }
  }
}

#Preview(traits: .withSearchContext) {
  TestSelectableGrid()
}
#endif
