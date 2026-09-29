import SwiftData
import SwiftUI

struct HistoryView: View {
  @Environment(\.colorScheme) private var scheme
  @Environment(\.isSearching) private var isSearching

  @Query private var history: [AlbumEntry]

  @State private var sort = SortModel()
  @State private var path = NavigationPath()
  @State private var searchText = ""

  let columns: [GridItem] = [
    .init(.flexible(), spacing: Spacing.md),
    .init(.flexible(), spacing: Spacing.md),
  ]

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView(.vertical) {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.md) {
          ForEach(sortedHistory) { entry in
            Button {
              path.append(entry)

            } label: {
              AlbumHistoryCard(entry: entry)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(Padding.xl)
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
      )
      .overlay {
        if history.isEmpty {
          ContentUnavailableView {
            Text("No albums yet")
              .font(.libreCaslonTextBold(.headline))

          } description: {
            Text("Music will show up here when you start identifying songs with ")
              .font(.libreCaslonTextRegular(.subheadline))
          }
        } else if sortedHistory.isEmpty {
          ContentUnavailableView.search
        }
      }
      .searchable(
        text: $searchText,
        prompt: "Search for artists or albums"
      )
      .toolbar {
        ToolbarTitle("History")
        ToolbarItem {
          Menu {
            Picker("Criteria", selection: $sort.criterion) {
              ForEach(SortCriterion.allCases) { criterion in
                Text(criterion.displayName)
                  .tag(criterion)
              }
            }

            Picker("Order", selection: currentOrder) {
              ForEach(sort.criterion.orders) { order in
                Text(order.displayName)
                  .tag(order)
              }
            }

          } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
          }
        }
      }
      .navigationDestination(for: AlbumEntry.self) { destination in
        AlbumDetailView(entry: destination)
      }
      .fullBackground(.themePrimary)
    }
  }

  private var currentOrder: Binding<SortOrder> {
    Binding(
      get: { sort.getOrder(for: sort.criterion) },
      set: { sort.setOrder($0, for: sort.criterion) }
    )
  }

  private var sortedHistory: [AlbumEntry] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    let order = sort.getOrder(for: sort.criterion)

    return
      history
      .filter { entry in
        query.isEmpty
          || entry.title.localizedCaseInsensitiveContains(query)
          || entry.artist.localizedCaseInsensitiveContains(query)
      }
      .sorted {
        sort.criterion.checkOrdered($0, $1, order: order)
      }
  }
}

#if DEBUG
  #Preview("No data", traits: .modifier(NoData())) {
    HistoryView()
  }

  #Preview("With data, in tab", traits: .modifier(SampleData())) {
    TabView {
      Tab {
        HistoryView()
      }
    }
    .environment(PreviewPlayer())
  }
#endif
