import SwiftUI

struct AlbumClusterView: View {
  init(
    albums: [Album],
    onSelect: @escaping (Album) -> Void,
  ) {
    self.groups = AlbumDateGroup.group(albums)
    self.onSelect = onSelect
  }

  private let groups: [AlbumDateGroup]
  private let onSelect: (Album) -> Void

  private let dateCutoff: Date = .now.subtracting(1, unit: .weekOfYear)

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Spacing.lg) {
        ForEach(groups) { group in
          ThemeSection {
            Section {
              ForEach(group.albums) { album in
                Button {
                  onSelect(album)
                } label: {
                  AlbumClusterRow(album: album)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
              }
            } header: {
              Text(group.formattedDate(cutoff: dateCutoff))
            }
          }
        }
      }
      .padding(Padding.xl)
    }
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .scrollClipDisabled()
  }
}

private struct AlbumDateGroup: Identifiable {
  let date: Date
  let albums: [Album]

  var id: Date { date }
}

extension AlbumDateGroup {
  func formattedDate(
    cutoff: Date = .now.subtracting(1, unit: .weekOfYear)
  ) -> String {
    let label: String

    if cutoff < date {
      label = date.formatted(Date.RelativeFormatStyle(allowedFields: [.day], presentation: .named))
    } else {
      label = date.formatted(date: .long, time: .omitted)
    }

    return label.capitalizingFirstLetter()
  }
}

extension String {
  func capitalizingFirstLetter() -> String {
    prefix(1).capitalized + dropFirst()
  }
}

extension AlbumDateGroup {
  static func group(
    _ albums: [Album],
    calendar: Calendar = .current,
  ) -> [Self] {
    Dictionary(grouping: albums) { album in
      calendar.startOfDay(for: album.selectedAt)
    }
    .map { date, albums in
      Self(
        date: date,
        albums: albums.sorted { $1.selectedAt < $0.selectedAt },
      )
    }
    .sorted { $1.date < $0.date }
  }
}

#if DEBUG
import SwiftData

private struct TestAlbumClusterView: View {
  @Query(sort: \Album.selectedAt, order: .reverse) var albums: [Album]

  var body: some View {
    AlbumClusterView(albums: albums) { _ in }
      .task {
        if let album = albums.first {
          album.isFavorite = true
        }
      }
      .task {
        let offsets: [DateOffset] = [
          .hours(1),
          .days(1),
          .days(2),
          .weeks(1),
          .months(1),
        ]

        guard albums.count >= offsets.count else { return }

        for (album, offset) in albums.paired(with: offsets, stride: 2) {
          album.selectedAt = album.selectedAt.subtracting(offset)
        }
      }
  }
}

private struct TestAlbumClusterSheet: View {
  @Query(sort: \Album.selectedAt, order: .reverse) var albums: [Album]

  @State private var isPresented = true

  var body: some View {
    Button("Show sheet") {
      isPresented = true
    }
    .sheet(isPresented: $isPresented) {
      NavigationStack {
        AlbumClusterView(albums: albums) { _ in }
          .presentationDetents([.medium, .large])
          .navigationBarTitleDisplayMode(.inline)
          .navigationTitle("Albums")
      }
    }
    .buttonStyle(.borderedProminent)
  }
}

#Preview("Grouped by date", traits: .withHistoryContext) {
  TestAlbumClusterView()
}
#Preview("With dates reset", traits: .withHistoryContext(kind: .resetDates(to: .now))) {
  TestAlbumClusterView()
}
#Preview("Sheet", traits: .withHistoryContext(kind: .resetDates(to: .now.subtracting(.days(1))))) {
  TestAlbumClusterSheet()
}
#endif
