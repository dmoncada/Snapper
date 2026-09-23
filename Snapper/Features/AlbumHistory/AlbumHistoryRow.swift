import SwiftUI

struct AlbumHistoryRow: View {
  let entry: AlbumHistoryEntry

  var body: some View {
    VStack(alignment: .leading) {
      Text(entry.title)
        .bold()

      if entry.artist.count > 0 {
        Text(entry.artist)
          .foregroundStyle(.secondary)
      }

      if entry.selection.candidate.displayMetadata.count > 0 {
        Text(entry.selection.candidate.displayMetadata)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Text(entry.selectedAt.formatted(date: .abbreviated, time: .shortened))
        .font(.caption)
        .foregroundStyle(.tertiary)

      if entry.latitude != nil, entry.longitude != nil {
        AlbumLocationDescription(entry: entry)
          .font(.caption)
      }
    }
  }
}
