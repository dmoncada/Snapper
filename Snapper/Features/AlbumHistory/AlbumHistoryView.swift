import SwiftData
import SwiftUI

struct HistoryView: View {
  /*
  @Environment(\.modelContext) private var context

  var body: some View {
    AlbumHistoryContent(context: context)
  }
}

private struct AlbumHistoryContent: View {
  @Environment(Router.self) private var router

  @State private var vm: AlbumHistoryViewModel
  @State private var path = NavigationPath()

  init(context: ModelContext) {
    _vm = State(initialValue: AlbumHistoryViewModel(context: context))
  }
   */

  @Environment(AlbumHistoryViewModel.self) private var vm
  @Environment(Router.self) private var router

  @State private var path = NavigationPath()

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
          AlbumSelectableCard(
            album: album,
            isSelecting: vm.isSelecting,
            isSelected: isSelected,
          )
          .contextMenu {
            if vm.isSelecting == false {
              FavoriteButton(album: album)
              DeleteButton {
                router.alertItem = AlertDestination(
                  title: "Delete Album?",
                  message: "Do you want to delete \"\(album.title)\" from your history?",
                  primary: .delete { vm.delete(album) },
                  secondary: .cancel,
                )
              }
            }
          }
        } header: {
          if vm.albumCount > 0 {
            FilterBar(
              selectedFilter: Binding(
                get: { vm.favoritesOnly ? .favorites : .all },
                set: { vm.favoritesOnly = $0 == .favorites },
              )
            )
            .padding(.vertical, Padding.md)
            .disabled(vm.isSelecting)
          }
        }
        // .onAppear { vm.isSelecting = false }
        .overlay {
          if filteredHistory.isEmpty {
            if vm.searchText.isEmpty {
              ContentUnavailableView {
                Text("No albums yet")
                  .font(.libreCaslonTextBold(.headline))
              } description: {
                Text("Music will show up here when you start identifying songs with MusicSnap")
                  .font(.libreCaslonTextRegular(.subheadline))
              }
            } else {
              ContentUnavailableView.search(text: vm.searchText)
            }
          }
        }
        .searchable(
          text: $vm.searchText,
          prompt: "Search for artists or albums",
        )
        .toolbar {
          AlbumHistoryToolbar(vm: vm)
        }
        .navigationDestination(for: Album.self) { destination in
          AlbumDetailWithActions(album: destination) { _ in
            vm.delete(destination)
            path.removeLast()
          }
        }
        .fullBackground(.themePrimary)
      }
    }
  }
}

private struct AlbumHistoryToolbar: ToolbarContent {
  @Environment(Router.self) private var router

  @Bindable var vm: AlbumHistoryViewModel

  var body: some ToolbarContent {
    ToolbarTitle("History")

    if vm.isSelecting {
      ToolbarItemGroup {
        Button(role: .cancel) {
          vm.clearSelection()
        }
        .accessibilityIdentifier("history-cancel-selection")

        Button(role: .destructive) {
          confirmBatchDelete()
        }
        .disabled(vm.selectedIds.isEmpty)
        .accessibilityIdentifier("history-delete-selection")
      }
    } else {
      ToolbarItem {
        Button("Select") {
          vm.isSelecting = true
        }
        .disabled(vm.filteredCount == 0)
      }

      ToolbarSpacer(.fixed)

      ToolbarItem {
        Menu {
          Picker("Criteria", selection: $vm.sort.criterion) {
            ForEach(SortCriterion.allCases) { criterion in
              Text(criterion.displayName)
                .tag(criterion)
            }
          }

          Picker("Order", selection: vm.currentOrder) {
            ForEach(vm.sort.criterion.orders) { order in
              Text(order.displayName)
                .tag(order)
            }
          }
        } label: {
          Image(systemName: "arrow.up.arrow.down")
        }
      }
    }
  }

  private func confirmBatchDelete() {
    let count = vm.selectedIds.count

    router.alertItem = AlertDestination(
      title: "Delete Albums?",
      message: "Delete all \(count) selected album(s) from your history?",
      primary: .delete { vm.batchDelete(ids: vm.selectedIds) },
      secondary: .cancel,
    )
  }
}

#if DEBUG
#Preview("No data", traits: .withoutData) {
  @Previewable @Environment(\.modelContext) var context

  @Previewable @State var router = Router()

  TabView {
    Tab {
      HistoryView()
    }
  }
  .withAlertDestination($router.alertItem)
  .environment(AlbumHistoryViewModel(context: context))
  .environment(router)
}

#Preview("With data", traits: .withSampleData) {
  @Previewable @Environment(\.modelContext) var context

  @Previewable @State var router = Router()

  TabView {
    Tab {
      HistoryView()
    }
  }
  .withAlertDestination($router.alertItem)
  .environment(AlbumHistoryViewModel(context: context))
  .environment(\.previewPlayer, .live)
  .environment(router)
}
#endif
