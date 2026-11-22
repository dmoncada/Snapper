import SwiftData
import SwiftUI

struct AlbumHistoryView: View {
  @Environment(AlbumHistoryViewModel.self) private var vm

  @Environment(\.navigation) private var navigation

  @Namespace private var namespace

  @State private var path = NavigationPath()
  @State private var alert: AlertDestination?

  var body: some View {
    @Bindable var vm = vm

    NavigationStack(path: $path) {
      DynamicQueryView(vm.descriptor) { filteredHistory in
        SelectableGrid(
          filteredHistory,
          selection: $vm.selectedIds,
          isSelecting: vm.isSelecting,
          onOpen: { path.append($0) },
        ) { album, isSelected in
          @Bindable var album = album

          AlbumSelectableCard(
            album: album,
            isSelecting: vm.isSelecting,
            isSelected: isSelected,
          )
          .matchedTransitionSource(
            id: album.persistentModelID,
            in: namespace,
          )
          .contextMenu {
            if vm.isSelecting == false {
              FavoriteButton(isFavorite: $album.isFavorite)
              DeleteButton(title: .toolsDeleteHistory) {
                alert = AlertDestination(
                  title: .alertsHistoryDeleteTitle(count: 1),
                  message: .alertsHistoryDeleteMessage(count: 1),
                  primary: .delete { vm.delete(album) },
                  secondary: .cancel,
                )
              }
            }
          }
        } header: {
          if vm.albumCount > 0 {
            AlbumHistoryFilterBar(vm: vm)
              .disabled(vm.isSelecting)
          }
        }
        .onAppear { vm.refreshAvailableFilters() }
        .overlay {
          if filteredHistory.isEmpty {
            if vm.searchText.isEmpty {
              ThemeContentUnavailableView.empty(
                .History.stateEmptyTitle,
                description: .History.stateEmptyDesc,
              ) {
                if let navigation {
                  EmptyStateButton(navigation: navigation)
                }
              }
            } else {
              ThemeContentUnavailableView.search(text: vm.searchText)
            }
          }
        }
        .searchable(
          text: $vm.searchText,
          prompt: .History.textfieldPlaceholder,
        )
        // .searchSuggestions {
        //   if vm.searchText.isEmpty {
        //     AlbumSearchSuggestions()
        //   }
        // }
        .navigationTitle(.History.title)
        .navigationSubtitle(
          Text(
            vm.isSelecting && vm.selectedIds.isEmpty == false
              ? .History.selected(count: vm.selectedIds.count)
              : .History.subtitle(count: vm.albumCount)
          )
        )
        .toolbar {
          albumHistoryToolbar {
            let count = vm.selectedIds.count
            alert = AlertDestination(
              title: .alertsHistoryDeleteTitle(count: count),
              message: .alertsHistoryDeleteMessage(count: count),
              primary: .delete { vm.batchDelete(ids: vm.selectedIds) },
              secondary: .cancel,
            )
          }
        }
        .navigationDestination(for: Album.self) { destination in
          AlbumDetailWithActions(album: destination) {
            vm.delete(destination)
            path.removeLast()
          }
          .navigationTransition(
            .zoom(
              sourceID: destination.persistentModelID,
              in: namespace,
            )
          )
        }
        .withAlertDestination($alert)
        .withFullBackground()
      }
    }
  }

  @ToolbarContentBuilder
  private func albumHistoryToolbar(
    deleteAction: @escaping () -> Void
  ) -> some ToolbarContent {
    // ToolbarTitle(.History.title)

    if vm.isSelecting {
      if vm.allSelected {
        ToolbarItem(placement: .topBarLeading) {
          Button(.toolsSelectAllUndo) {
            withAnimation {
              vm.deselectAll(vm.filteredIds)
            }
          }
          // TODO: logic for disabling button.
        }
      } else {
        ToolbarItem(placement: .topBarLeading) {
          Button(.toolsSelectAll) {
            withAnimation {
              vm.selectAll(vm.filteredIds)
            }
          }
          // TODO: logic for disabling button.
        }
      }

      ToolbarItemGroup(placement: .topBarTrailing) {
        Button(role: .cancel) {
          withAnimation {
            vm.clearSelection()
          }
        }
        .accessibilityIdentifier("history-cancel-selection")

        Button(role: .destructive) {
          deleteAction()
        }
        .disabled(vm.selectedIds.isEmpty)
        .accessibilityIdentifier("history-delete-selection")
      }
    } else {
      ToolbarItem(placement: .topBarTrailing) {
        Button(.toolsSelect) {
          withAnimation {
            vm.isSelecting = true
          }
        }
        .disabled(vm.filteredCount == 0)
      }

      ToolbarSpacer(.fixed, placement: .topBarTrailing)

      ToolbarItem(placement: .topBarTrailing) {
        @Bindable var vm = vm

        Menu {
          Picker(.toolsSortCriteria, selection: $vm.sort.criterion) {
            ForEach(SortCriterion.allCases) { criterion in
              Text(criterion.resource)
                .tag(criterion)
            }
          }

          Picker(.toolsSortDirection, selection: vm.currentOrder) {
            ForEach(vm.sort.criterion.orders) { order in
              Text(order.resource)
                .tag(order)
            }
          }
        } label: {
          Label(.toolsSort, systemImage: "arrow.up.arrow.down")
        }
      }
    }
  }
}

private struct EmptyStateButton: View {
  var navigation: AppNavigation

  var body: some View {
    Button(.History.stateEmptyButtonLabel, systemImage: "magnifyingglass") {
      navigation.screen = .search
    }
    .labelStyle(.badge(appearance: .highlighted))
    .controlSize(.large)
    .imageScale(.small)
  }
}

private struct AlbumSearchSuggestions: View {
  @Query(sort: \Album.title) private var albums: [Album]

  let maxResults: Int

  init(maxResults: Int = 3) {
    self.maxResults = maxResults
  }

  var titles: [String] {
    Array(albums.map(\.title).prefix(min(albums.count, maxResults)))
  }

  var body: some View {
    ForEach(titles, id: \.self) { title in
      Text(title)
        .searchCompletion(title)
    }
  }
}

private struct AlbumHistoryFilterBar: View {
  @Environment(\.locale) private var locale

  @Bindable var vm: AlbumHistoryViewModel

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: Spacing.sm) {
        ForEach(vm.sortedAvailableFilters(locale: locale)) { filter in
          Toggle(
            filter.resource,
            systemImage: "checkmark",
            isOn: $vm[isSelected: filter],
          )
          .toggleStyle(
            .titleAndIconBadge(
              labelStyle: .expand,
              appearance: vm[isSelected: filter]
                ? .highlighted
                : .default,
            )
          )
          .imageScale(.small)
        }
      }
      .padding(LineWidth.sm)
    }
  }
}

#if DEBUG
private struct WithNoResults: View {
  @Environment(AlbumHistoryViewModel.self) private var vm

  @Query(sort: \Album.selectedAt, order: .reverse) private var albums: [Album]

  var body: some View {
    AlbumHistoryView()
      .onAppear {
        vm.searchText = "#"
      }
  }
}

private struct WithDatesReset: View {
  @Query(sort: \Album.title) private var albums: [Album]

  var body: some View {
    AlbumHistoryView()
      .onAppear {
        let offsets: [DateOffset] = [
          .seconds(30),
          .minutes(1),
          .hours(1),
          .days(1),
          .weeks(1),
          .months(1),
          .years(1),
        ]

        guard albums.count >= offsets.count else { return }

        for (album, offset) in albums.paired(with: offsets) {
          album.selectedAt = album.selectedAt.subtracting(offset)
        }
      }
  }
}

#Preview("Empty", traits: .withHistoryContext(kind: .empty)) {
  AlbumHistoryView()
}
#Preview("No results", traits: .withHistoryContext(kind: .default)) {
  WithNoResults()
}
#Preview("With data", traits: .withHistoryContext(kind: .default)) {
  AlbumHistoryView()
}
#Preview("With dates reset", traits: .withHistoryContext(kind: .resetDates(to: .now))) {
  WithDatesReset()
}
#Preview("In tab", traits: .withHistoryContext(kind: .default)) {
  TabView {
    Tab("History", systemImage: "clock") {
      AlbumHistoryView()
    }
  }
}
#endif
