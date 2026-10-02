import SwiftData
import SwiftUI

struct HistoryView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.isSearching) private var isSearching
  @Environment(Router.self) private var router

  @Query private var history: [AlbumEntry]

  @State private var sort = SortModel()
  @State private var path = NavigationPath()

  @State private var searchText = ""
  @State private var favoritesOnly = false

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
                .contextMenu {
                  FavoriteButton(entry: entry)
                  DeleteButton {
                    router.alertItem = AlertDestination(
                      title: "Delete Album?",
                      message:
                        "Are you sure you want to delete \"\(entry.title)\" from your history?",
                      primary: .init(title: "Delete", role: .destructive) {
                        context.delete(entry)
                      },
                      secondary: .init(title: "Cancel", role: .cancel),
                    )
                  }
                }
            }
            .buttonStyle(.plain)
          }
        }
        .padding(Padding.xl)
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
      )
      .overlay {
        if history.isEmpty {
          ContentUnavailableView {
            Text("No albums yet")
              .font(.libreCaslonTextBold(.headline))
          } description: {
            Text("Music will show up here when you start identifying songs with MusicSnap")
              .font(.libreCaslonTextRegular(.subheadline))
          }
        } else if sortedHistory.isEmpty {
          ContentUnavailableView.search
        }
      }
      .searchable(
        text: $searchText,
        prompt: "Search for artists or albums",
      )
      .toolbar {
        ToolbarTitle("History")
        ToolbarItem {
          Menu {
            Toggle(isOn: $favoritesOnly) {
              Label("Favorites", systemImage: "star")
            }

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
            Image(systemName: "arrow.up.arrow.down")
          }
        }
      }
      .navigationDestination(for: AlbumEntry.self) { destination in
        AlbumDetailWithActions(entry: destination) { _ in
          context.delete(destination)
          path.removeLast()
        }
      }
      .fullBackground(.themePrimary)
    }
  }

  private var currentOrder: Binding<SortOrder> {
    Binding(
      get: { sort.getOrder(for: sort.criterion) },
      set: { sort.setOrder($0, for: sort.criterion) },
    )
  }

  private var sortedHistory: [AlbumEntry] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    let order = sort.getOrder(for: sort.criterion)

    return
      history
      .filter { entry in
        let matchesSearch =
          query.isEmpty
          || entry.title.localizedCaseInsensitiveContains(query)
          || entry.artist.localizedCaseInsensitiveContains(query)

        let matchesFavorite = favoritesOnly == false || entry.isFavorited

        return matchesSearch && matchesFavorite
      }
      .sorted {
        sort.criterion.checkOrdered($0, $1, order: order)
      }
  }
}

#if DEBUG
#Preview("No data", traits: .modifier(NoData())) {
  @Previewable @State var router = Router()

  TabView {
    Tab {
      HistoryView()
    }
  }
  .withAlertDestination($router.alertItem)
  .environment(router)
}

#Preview("With data", traits: .modifier(SampleData())) {
  @Previewable @State var router = Router()

  TabView {
    Tab {
      HistoryView()
    }
  }
  .withAlertDestination($router.alertItem)
  .environment(PreviewPlayer())
  .environment(router)
}
#endif
