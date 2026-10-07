import SwiftData
import SwiftUI

struct HistoryView: View {
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

  var body: some View {
    NavigationStack(path: $path) {
      DynamicQueryView(vm.descriptor) { history in
        SelectableGrid(
          history,
          selection: $vm.selectedIds,
          isSelecting: vm.isSelecting,
          onOpen: { path.append($0) },
        ) { entry, isSelected in
          AlbumSelectableCard(
            entry: entry,
            isSelecting: vm.isSelecting,
            isSelected: isSelected,
          )
          .contextMenu {
            if vm.isSelecting == false {
              FavoriteButton(entry: entry)
              DeleteButton {
                router.alertItem = AlertDestination(
                  title: "Delete Album?",
                  message: "Do you want to delete \"\(entry.title)\" from your history?",
                  primary: .delete { vm.delete(entry) },
                  secondary: .cancel,
                )
              }
            }
          }
        }
        .frame(
          maxWidth: .infinity,
          maxHeight: .infinity,
        )
        .onAppear { vm.isSelecting = false }
        .overlay {
          if history.isEmpty {
            ContentUnavailableView {
              Text("No albums yet")
                .font(.libreCaslonTextBold(.headline))
            } description: {
              Text("Music will show up here when you start identifying songs with MusicSnap")
                .font(.libreCaslonTextRegular(.subheadline))
            }
          } else if history.isEmpty {
            ContentUnavailableView.search
          }
        }
        .searchable(
          text: $vm.searchText,
          prompt: "Search for artists or albums",
        )
        .toolbar {
          ToolbarTitle("History")

          if vm.isSelecting {
            ToolbarItemGroup {
              Button(role: .cancel) {
                vm.cancelSelection()
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
              .disabled(history.isEmpty)
            }

            ToolbarSpacer(.fixed)

            ToolbarItem {
              Menu {
                Toggle(isOn: $vm.favoritesOnly) {
                  Label("Favorites", systemImage: "star")
                }

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
                // TODO(dmoncada): figure out proper way to tint button.
                Image(systemName: "ellipsis")
                  .frame(
                    width: 32,
                    height: 32,
                  )
                  .foregroundStyle(
                    vm.favoritesOnly
                      ? .themePrimary
                      : .themePrimaryInverted
                  )
                  .background {
                    if vm.favoritesOnly {
                      Circle().fill(.tint)
                    }
                  }
              }
            }
          }
        }
        .navigationDestination(for: AlbumEntry.self) { destination in
          AlbumDetailWithActions(entry: destination) { _ in
            vm.delete(destination)
            path.removeLast()
          }
        }
        .fullBackground(.themePrimary)
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
  @Previewable @State var router = Router()

  TabView {
    Tab {
      HistoryView()
    }
  }
  .withAlertDestination($router.alertItem)
  .environment(router)
}

#Preview("With data", traits: .withSampleData) {
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
