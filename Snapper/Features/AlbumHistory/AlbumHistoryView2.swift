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
                .init(.flexible(), spacing: Spacing.md),
                .init(.flexible(), spacing: Spacing.md),
              ],
              alignment: .leading,
              spacing: Spacing.md
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
          .asyncImageURLSession(.images)
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
      get: { sortOrders[sortCriterion] ?? sortCriterion.defaultOrder },
      set: { sortOrders[sortCriterion] = $0 }
    )
  }
}

private struct AlbumHistoryItem: View {
  let entry: AlbumEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      AlbumCover(url: URL(string: entry.coverImageUrlString ?? ""))
        .roundedOutline(radius: Radius.md, lineWidth: 1)

      HStack {
        VStack(alignment: .leading, spacing: Spacing.xs) {
          Text(entry.title)
            .font(.sligoilMicroBold(.caption))

          Text(entry.artist)
            .font(.sligoilMicro(.caption2))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .minimumScaleFactor(0.5)
        .lineLimit(1)

        Spacer()

        Text((entry.selectedAt.shortRelativeTime(to: .now)))
          .padding(Padding.md)
          .font(.sligoilMicroMedium(.caption2))
          .roundedOutline(radius: Radius.md, lineWidth: 1)
      }
      .frame(height: 40)
    }
  }
}

private struct AlbumCover: View {
  let url: URL?

  var body: some View {
    Color.gray
      .frame(maxWidth: .infinity)
      .aspectRatio(1, contentMode: .fit)
      .overlay {
        AlbumCoverImage(url: url)
          .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
          )
          .clipped()
      }
  }
}

private struct AlbumCoverImage: View {
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

#Preview("No data", traits: .modifier(NoData())) {
  HistoryView()
}

#Preview("With data", traits: .modifier(SampleData())) {
  HistoryView()
}
