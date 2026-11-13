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

  private let dateCutoff: Date = .now.subtract(1, unit: .weekOfYear)

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
    cutoff: Date = .now.subtract(1, unit: .weekOfYear)
  ) -> String {
    let formatted: String

    if Calendar.current.isDateInToday(date) {
      return String(localized: "Today")
    } else if date < cutoff {
      return date.formatted(.dateTime.day().month().year()).capitalizingFirstLetter()
    } else {
      return date.formatted(.relative(presentation: .named)).capitalizingFirstLetter()
    }
  }
}

extension String {
  func capitalizingFirstLetter() -> String {
    prefix(1).capitalized + dropFirst()
  }

  mutating func capitalizeFirstLetter() {
      self = self.capitalizingFirstLetter()
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
        let offsets: [(value: Int, unit: Calendar.Component)] = [
          (1, .hour),
          (1, .day),
          (2, .day),
          (1, .weekOfYear),
          (1, .month),
        ]

        guard albums.count >= offsets.count else { return }

        for (album, offset) in albums.withOffsets(offsets, stride: 2) {
          album.selectedAt = album.selectedAt.subtract(
            offset.value,
            unit: offset.unit,
          )
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

#Preview("Grouped", traits: .withSearchContext) {
  TestAlbumClusterView()
}

#Preview("Sheet", traits: .withSearchContext) {
  TestAlbumClusterSheet()
}
#endif
