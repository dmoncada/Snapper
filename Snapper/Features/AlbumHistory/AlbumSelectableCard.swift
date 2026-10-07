import SwiftUI

struct AlbumSelectableCard: View {
  let entry: AlbumEntry
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

      AlbumHistoryCard(entry: entry)
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
  let entries: [AlbumEntry]

  @State private var selection = Set<AlbumEntry.ID>()

  var body: some View {
    NavigationStack {
      SelectableGrid(
        entries,
        selection: $selection,
        isSelecting: true,
        onOpen: { _ in },
      ) { entry, isSelected in
        AlbumSelectableCard(
          entry: entry,
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
  @Previewable @Query(sort: \AlbumEntry.selectedAt) var entries: [AlbumEntry]

  if entries.isEmpty {
    ProgressView()
  } else {
    TestSelectableGrid(entries: entries)
  }
}
#endif
