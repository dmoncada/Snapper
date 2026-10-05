import SwiftUI

struct AlbumSelectableCard: View {
  let entry: AlbumEntry
  let isSelecting: Bool
  let isSelected: Bool

  var body: some View {
    AlbumHistoryCard(entry: entry)
      .background {
        if isSelecting && isSelected {
          VStack(spacing: 0) {
            let fill = Color.accentColor.opacity(0.25)

            RoundedRectangle(cornerRadius: Radius.md)
              .fill(fill)
            Rectangle()
              .fill(fill)
          }
        }
      }
      .overlay(alignment: .topTrailing) {
        if isSelecting {
          Group {
            if isSelected {
              Image(systemName: "checkmark.circle.fill")
                .transition(.symbolEffect(.drawOn, options: .speed(0.75)))
                .foregroundStyle(.selection)
            } else {
              Image(systemName: "circle")
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

import SwiftData

#Preview(traits: .withSampleData) {
  @Previewable @Query(sort: \AlbumEntry.selectedAt) var entries: [AlbumEntry]

  if entries.isEmpty {
    ProgressView()
  } else {
    TestSelectableGrid(entries: entries)
  }
}
#endif
