import SwiftUI

struct Item: Identifiable {
  let id: UUID
  let title: String
  let genres: Set<Genre>
  var isFavorite: Bool
}

enum ItemFilter: Hashable, Identifiable {
  case all
  case favorites
  case genre(Genre)

  var id: Self { self }

  var title: String {
    switch self {
    case .all: "All"
    case .favorites: "Favorites"
    case .genre(let genre): genre.title
    }
  }
}

struct FilterBar: View {
  @Binding var selectedFilters: Set<ItemFilter>

  let filters: [ItemFilter]

  private func toggle(_ filter: ItemFilter) {
    if filter == .all {
      selectedFilters = [.all]
      return
    }

    selectedFilters.remove(.all)

    if selectedFilters.contains(filter) {
      selectedFilters.remove(filter)
    } else {
      selectedFilters.insert(filter)
    }

    if selectedFilters.isEmpty {
      selectedFilters = [.all]
    }
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: Spacing.sm) {
        ForEach(filters) { filter in
          let isOn = selectedFilters.contains(filter)

          Toggle(
            filter.title,
            systemImage: "checkmark",
            isOn: Binding(
              get: { isOn },
              set: { _ in toggle(filter) },
            ),
          )
          .titleAndIconBadgeToggleStyle(
            labelStyle: .expand,
            appearance: isOn
              ? .highlighted
              : .default,
          )
          .imageScale(.small)
        }
      }
      .padding(1)
    }
  }
}

struct ItemListView: View {
  @State private var selectedFilters: Set<ItemFilter> = [.all]

  @State private var items: [Item] = [
    Item(
      id: UUID(),
      title: "Item 1",
      genres: [.rock, .pop, .jazz],
      isFavorite: true,
    ),
    Item(
      id: UUID(),
      title: "Item 2",
      genres: [.pop, .jazz],
      isFavorite: false,
    ),
    Item(
      id: UUID(),
      title: "Item 3",
      genres: [.jazz, .electronic],
      isFavorite: true,
    ),
  ]

  private var filters: [ItemFilter] {
    let availableGenres = Set(items.flatMap(\.genres))

    return
      [
        .all,
        .favorites,
      ]
      + Genre.allCases
      .filter { availableGenres.contains($0) }
      .map(ItemFilter.genre)
  }

  private var filteredItems: [Item] {
    if selectedFilters.contains(.all) {
      return items
    }

    return items.filter { item in
      selectedFilters.contains { filter in
        switch filter {
        case .all:
          true

        case .favorites:
          item.isFavorite

        case .genre(let genre):
          item.genres.contains(genre)
        }
      }
    }
  }

  var body: some View {
    ScrollView {
      FilterBar(
        selectedFilters: $selectedFilters,
        filters: filters,
      )

      LazyVStack(spacing: 0) {
        ForEach(filteredItems) { item in
          LabeledContent {
            Text(
              item.genres
                .map(\.title)
                .sorted()
                .joined(separator: ", ")
            )
            .font(.caption)
            .foregroundStyle(.secondary)
          } label: {
            HStack {
              Text(item.title)

              if item.isFavorite {
                Image(systemName: "heart.fill")
                  .foregroundStyle(.red)
              }
            }
          }
          .padding(.vertical)

          Divider()
        }
      }
    }
    .padding(.horizontal)
    .onChange(of: filters) { _, newFilters in
      selectedFilters.formIntersection(newFilters)

      if selectedFilters.isEmpty {
        selectedFilters = [.all]
      }
    }
  }
}

#Preview {
  ItemListView()
}
