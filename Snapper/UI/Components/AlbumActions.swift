import SwiftData
import SwiftUI

struct FavoriteButton: View {
  @Binding var isFavorite: Bool

  var body: some View {
    Button {
      isFavorite.toggle()
    } label: {
      let title: LocalizedStringResource =
        isFavorite
        ? .toolsFavoriteUndo
        : .toolsFavorite

      Label(title, systemImage: "heart")
        .symbolVariant(
          isFavorite
            ? .slash
            : .none
        )
    }
  }
}

struct DeleteButton: View {
  let title: LocalizedStringResource
  let action: () -> Void

  init(
    title: LocalizedStringResource,
    action: @escaping () -> Void,
  ) {
    self.title = title
    self.action = action
  }

  var body: some View {
    Button(role: .destructive) {
      action()
    } label: {
      Label(title, systemImage: "trash")
    }
  }
}

#if DEBUG
import SwiftData

#Preview {
  @Previewable @State var isFavorite = false

  NavigationStack {
    HStack {
      Text("Hello, world!")
      Image(systemName: "heart")
        .symbolVariant(isFavorite ? .slash : .none)
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          FavoriteButton(isFavorite: $isFavorite)
          DeleteButton(title: .toolsDelete) {
            print("Deleted")
          }
        } label: {
          Image(systemName: "ellipsis")
        }
      }
    }
  }
}
#endif
