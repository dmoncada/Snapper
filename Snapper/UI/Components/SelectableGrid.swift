import SwiftUI

struct SelectableGrid<
  Item: Identifiable,
  Cell: View,
>: View where Item.ID: Hashable {
  let items: [Item]
  let isSelecting: Bool
  let onOpen: (Item) -> Void

  @Binding var selection: Set<Item.ID>

  let columns: [GridItem]

  @ViewBuilder let cell: (Item, Bool) -> Cell

  init(
    _ items: [Item],
    selection: Binding<Set<Item.ID>>,
    isSelecting: Bool,
    columns: [GridItem] = [
      .init(.flexible(), spacing: Spacing.sm),
      .init(.flexible(), spacing: Spacing.sm),
    ],
    onOpen: @escaping (Item) -> Void,
    @ViewBuilder cell: @escaping (Item, Bool) -> Cell,
  ) {
    self.items = items
    self._selection = selection
    self.isSelecting = isSelecting
    self.columns = columns
    self.onOpen = onOpen
    self.cell = cell
  }

  var body: some View {
    ScrollView(.vertical) {
      LazyVGrid(
        columns: columns,
        alignment: .leading,
        spacing: Spacing.sm,
      ) {
        ForEach(items) { item in
          SelectableView(
            id: item.id,
            isSelecting: isSelecting,
            onOpen: { onOpen(item) },
            selection: $selection,
          ) { isSelected in
            cell(item, isSelected)
          }
        }
      }
      .padding(Padding.xl)
    }
  }
}
