import SwiftUI

struct SelectableView<
  ID: Hashable,
  Content: View,
>: View {
  let id: ID
  let isSelecting: Bool
  let onOpen: () -> Void

  @Binding var selection: Set<ID>

  @ViewBuilder let content: (Bool) -> Content

  private var isSelected: Bool {
    selection.contains(id)
  }

  var body: some View {
    Button {
      if isSelecting {
        if isSelected {
          selection.remove(id)
        } else {
          selection.insert(id)
        }
      } else {
        onOpen()
      }
    } label: {
      content(isSelected)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(
      isSelecting && isSelected
        ? .isSelected
        : []
    )
  }
}
