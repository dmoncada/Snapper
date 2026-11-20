import SwiftData
import SwiftUI

struct HistoryView: View {
  @Environment(AlbumHistoryViewModel.self) private var vm

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
              )
            } else {
              ThemeContentUnavailableView.search(text: vm.searchText)
            }
          }
        }
        .searchable(
          text: $vm.searchText,
          prompt: .History.textfieldPlaceholder,
        )
        .toolbar {
          AlbumHistoryToolbar(vm: vm) {
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
        }
        .withAlertDestination($alert)
        .withFullBackground()
      }
    }
  }
}

private struct AlbumHistoryToolbar: ToolbarContent {
  @Bindable var vm: AlbumHistoryViewModel

  let deleteAction: () -> Void

  var body: some ToolbarContent {
    ToolbarTitle(.History.title)

    if vm.isSelecting {
      ToolbarItemGroup {
        Button(role: .cancel) {
          vm.clearSelection()
        }
        .accessibilityIdentifier("history-cancel-selection")

        Button(role: .destructive) {
          deleteAction()
        }
        .disabled(vm.selectedIds.isEmpty)
        .accessibilityIdentifier("history-delete-selection")
      }
    } else {
      ToolbarItem {
        Button(.toolsSelect) {
          vm.isSelecting = true
        }
        .disabled(vm.filteredCount == 0)
      }

      ToolbarSpacer(.fixed)

      ToolbarItem {
        Menu {
          Picker("Criteria", selection: $vm.sort.criterion) {
            ForEach(SortCriterion.allCases) { criterion in
              Text(criterion.resource)
                .tag(criterion)
            }
          }

          Picker("Order", selection: vm.currentOrder) {
            ForEach(vm.sort.criterion.orders) { order in
              Text(order.resource)
                .tag(order)
            }
          }
        } label: {
          Image(systemName: "arrow.up.arrow.down")
        }
      }
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
    HistoryView()
      .onAppear {
        vm.searchText = "#"
      }
  }
}

private struct WithDatesReset: View {
  @Query(sort: \Album.title) private var albums: [Album]

  var body: some View {
    HistoryView()
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
  HistoryView()
}
#Preview("No results", traits: .withHistoryContext(kind: .default)) {
  WithNoResults()
}
#Preview("With data", traits: .withHistoryContext(kind: .default)) {
  HistoryView()
}
#Preview("With dates reset", traits: .withHistoryContext(kind: .resetDates(to: .now))) {
  WithDatesReset()
}
#Preview("In tab", traits: .withHistoryContext(kind: .default)) {
  TabView {
    Tab {
      HistoryView()
    }
  }
}
#endif
