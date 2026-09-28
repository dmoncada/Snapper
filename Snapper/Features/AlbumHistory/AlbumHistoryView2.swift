import SwiftData
import SwiftUI

struct HistoryView: View {
  @Environment(\.colorScheme) private var scheme

  @Query(sort: \AlbumEntry.selectedAt, order: .reverse)
  private var history: [AlbumEntry]

  @State private var path = NavigationPath()
  @State private var sortCriterion: SortCriterion = .dateFound
  @State private var sortOrders: [SortCriterion: SortOrder] = [
    .dateFound: .newestFirst,
    .songTitle: .ascending,
    .artistName: .ascending,
  ]

  let columns: [GridItem] = [
    .init(.flexible(), spacing: Spacing.md),
    .init(.flexible(), spacing: Spacing.md),
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
            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.md) {
              ForEach(history) { entry in
                Button {
                  path.append(entry)

                } label: {
                  AlbumHistoryCard(entry: entry)
                }
                .buttonStyle(.plain)
              }
            }
            .padding(.vertical, Padding.xl)
          }
        }
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
      )
      .padding(.horizontal, Padding.xl)
      .toolbarBackground(.thinMaterial, for: .navigationBar)
      .toolbarBackgroundVisibility(.visible, for: .navigationBar)
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

#if DEBUG
  #Preview("No data", traits: .modifier(NoData())) {
    HistoryView()
  }

  #Preview("With data", traits: .modifier(SampleData())) {
    HistoryView()
  }
#endif
