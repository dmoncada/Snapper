import SwiftUI

struct AlbumSelectableCard: View {
  let album: Album
  let isSelecting: Bool
  let isSelected: Bool

  var body: some View {
    ZStack {
      if isSelecting && isSelected {
        ConcentricRectangle(
          uniformTopCorners: .concentric,
          uniformBottomCorners: .fixed(0),
        )
        .fill(.accent.opacity(0.25))
      }

      AlbumHistoryCard(album: album)
        .padding(Padding.sm)
    }
    .containerShape(.rect(cornerRadius: Radius.md))
    .overlay(alignment: .topTrailing) {
      if isSelecting {
        Group {
          if isSelected {
            Icon(systemName: "checkmark.circle.fill")
              .transition(.symbolEffect(.drawOn, options: .speed(0.75)))
              .foregroundStyle(.selection)
          } else {
            Icon(systemName: "circle")
              .foregroundStyle(.secondary)
          }
        }
        .padding(Padding.lg)
      }
    }
    .animation(
      .easeOut(duration: 0.25),
      value: isSelected,
    )
  }
}

#if DEBUG
import SwiftData

private struct TestSelectableGrid: View {
  let albums: [Album]

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
    }
  }
}

#Preview(traits: .withSampleData) {
  @Previewable @Query(sort: \Album.selectedAt, order: .reverse) var albums: [Album]

  if albums.isEmpty {
    ProgressView()
  } else {
    TestSelectableGrid(albums: albums)
  }
}
#endif
