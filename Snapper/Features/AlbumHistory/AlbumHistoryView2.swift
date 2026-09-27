import SwiftData
import SwiftUI

struct HistoryView: View {
  @Query(sort: \AlbumEntry.selectedAt, order: .reverse)
  private var history: [AlbumEntry]

  @State private var path = NavigationPath()
  @State private var sortCriterion: SortCriterion = .dateFound
  @State private var sortOrders: [SortCriterion: SortOrder] = [
    .dateFound: .newestFirst,
    .songTitle: .ascending,
    .artistName: .ascending,
  ]

  var body: some View {
    NavigationStack(path: $path) {
      Group {
        if history.isEmpty {
          ContentUnavailableView {
            Text("No albums yet")
              .font(.libreCaslonTextBold(.headline))

          } description: {
            Text("Music will show up here when you start identifying songs with ")
              .font(.libreCaslonTextRegular(.subheadline))
          }

        } else {
          ScrollView(.vertical) {
            LazyVGrid(
              columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
              ],
              alignment: .leading,
              spacing: Spacing.lg
            ) {
              ForEach(history) { entry in
                Button {
                  path.append(entry)

                } label: {
                  AlbumHistoryItem(entry: entry)
                }
                .buttonStyle(.plain)
              }
            }
          }
          .scrollIndicators(.hidden)
        }
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
      )
      .padding()
      .toolbar {
        ToolbarTitle("History")
        ToolbarItemGroup {
          Menu {
            Picker("Criteria", selection: $sortCriterion) {
              ForEach(SortCriterion.allCases) { criterion in
                Text(criterion.displayName)
                  .tag(criterion)
              }
            }

            Picker("Order", selection: currentOrder) {
              ForEach(sortCriterion.orders) { order in
                Text(order.displayName)
                  .tag(order)
              }
            }

          } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
          }

          Button("Search", systemImage: "magnifyingglass") {}
            .labelStyle(.iconOnly)
        }
      }
      .navigationDestination(for: AlbumEntry.self) { destination in
        AlbumDetailView2(entry: destination)
      }
      .fullBackground(.themePrimary)
    }
  }

  private var currentOrder: Binding<SortOrder> {
    Binding(
      get: {
        sortOrders[sortCriterion] ?? sortCriterion.defaultOrder
      },
      set: {
        sortOrders[sortCriterion] = $0
      }
    )
  }
}

private struct AlbumHistoryItem: View {
  let entry: AlbumEntry

  var body: some View {
    VStack(alignment: .leading) {
      AlbumCover2(url: URL(string: entry.coverImageUrlString ?? ""))
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(.rect(cornerRadius: Radius.md))

      HStack {
        VStack(alignment: .leading, spacing: Spacing.xs) {
          Text(entry.title)
            .font(.sligoilMicroBold(.caption))

          Text(entry.artist)
            .font(.sligoilMicro(.caption2))
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)

        Spacer()

        Text((entry.selectedAt.shortRelativeTime(to: .now)))
          .padding(Padding.md)
          .font(.sligoilMicroMedium(.caption2))
          .roundedOutline(radius: Radius.md, lineWidth: 1)
      }
    }
  }
}

extension Date {
  fileprivate func shortRelativeTime(to now: Date = .now) -> String {
    let seconds = max(0, now.timeIntervalSince(self))

    let minute = 60.0
    let hour = 60.0 * minute
    let day = 24.0 * hour
    let week = 7.0 * day
    let month = 30.0 * day
    let year = 365.0 * day

    switch seconds {
    case 0 ..< hour:
      return "\(max(1, Int(seconds / minute)))m"
    case 0 ..< day:
      return "\(Int(seconds / hour))h"
    case 0 ..< week:
      return "\(Int(seconds / day))d"
    case 0 ..< month:
      return "\(Int(seconds / week))w"
    case 0 ..< year:
      return "\(Int(seconds / month))mo"
    default:
      return "\(Int(seconds / year))y"
    }
  }

}

private struct AlbumCover: View {
  let url: URL?

  var body: some View {
    AsyncImage(url: url) { image in
      image
        .resizable()
        .scaledToFill()

    } placeholder: {
      ProgressView()
    }
    .frame(maxWidth: .infinity)
    .aspectRatio(1, contentMode: .fit)
    .clipShape(.rect(cornerRadius: Radius.sm))
  }
}

private struct AlbumCover2: View {
  let url: URL?

  var body: some View {
    AsyncImage(url: url) { phase in
      switch phase {
      case .empty:
        ZStack {
          Color.gray
          ProgressView()
            .tint(.white)
        }

      case .success(let image):
        image
          .resizable()
          .scaledToFill()

      case .failure:
        Color.gray

      @unknown default:
        Color.gray
      }
    }
    .asyncImageURLSession(.images)
    .frame(maxWidth: .infinity)
    .clipped()
  }
}

enum SortCriterion: String, CaseIterable, Identifiable {
  case dateFound, songTitle, artistName

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .dateFound: "Date Found"
    case .songTitle: "Song Title"
    case .artistName: "Artist Name"
    }
  }
}

enum SortOrder: String, CaseIterable, Identifiable {
  case newestFirst, oldestFirst
  case ascending, descending

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .newestFirst: "Newest First"
    case .oldestFirst: "Oldest First"
    case .ascending: "Ascending"
    case .descending: "Descending"
    }
  }
}

extension SortCriterion {
  fileprivate var defaultOrder: SortOrder {
    switch self {
    case .dateFound: .newestFirst
    case .songTitle, .artistName: .ascending
    }
  }

  fileprivate var orders: [SortOrder] {
    switch self {
    case .dateFound: [.newestFirst, .oldestFirst]
    case .songTitle, .artistName: [.ascending, .descending]
    }
  }
}

#Preview {
  let container = try? ModelContainer(
    for: AlbumEntry.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )

  guard let container else { return EmptyView() }

  let album = AlbumCandidate(
    id: 21491,
    artist: "Radiohead",
    title: "OK Computer",
    year: 1997,
    formats: ["CD", "Vinyl", "Cassette"],
    labels: ["Parlophone"],
    country: "United Kingdom",
    thumbnailUrl: URL(
      string:
        "https://i.discogs.com/OaKbbnsKGXwq2llV8ZlLi-QJgKz2S-Wm3NdJfmHKpgU/rs:fit/g:sm/q:40/h:150/w:150/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9SLTg2NjQz/ODQtMTY5NzQ3NDg3/Ny0zMTYxLmpwZWc.jpeg",
    ),
    coverImageUrl: URL(
      string:
        "https://i.discogs.com/YTJxCXA7Z04Ve01kFU5EEsOVN6Xik62J7zgNbCtOBlk/rs:fit/g:sm/q:90/h:601/w:600/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9SLTg2NjQz/ODQtMTY5NzQ3NDg3/Ny0zMTYxLmpwZWc.jpeg",
    ),
    discogsUrl: URL(string: "https://www.discogs.com/master/21491")
  )

  let context = container.mainContext

  context.insert(AlbumEntry(candidate: album, selectedAt: .now.addingTimeInterval(-1)))
  context.insert(AlbumEntry(candidate: album, selectedAt: .now.addingTimeInterval(-3 * 60)))
  context.insert(AlbumEntry(candidate: album, selectedAt: .now.addingTimeInterval(-5 * 60 * 60)))

  return HistoryView()
    .modelContainer(container)
}
