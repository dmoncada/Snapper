import SwiftUI

struct SelectionIndicator: View {
  let isSelected: Bool
  let size: CGFloat

  init(
    isSelected: Bool,
    size: CGFloat = 24,
  ) {
    self.isSelected = isSelected
    self.size = size
  }

  private let idleColor: Color = .themeOffWhite

  var body: some View {
    Image(
      systemName: isSelected
        ? "checkmark.circle.fill"
        : "circle"
    )
    .resizable()
    .scaledToFit()
    .frame(width: size, height: size)
    .foregroundStyle(
      isSelected
        ? AnyShapeStyle(.selection)
        : AnyShapeStyle(idleColor)
    )
    .background {
      Circle()
        .fill(
          isSelected
            ? AnyShapeStyle(idleColor)
            : AnyShapeStyle(.clear)
        )
    }
    .padding(Padding.lg)
  }
}

#if DEBUG
private struct Card: View {
  @Binding var isSelected: Bool

  let size: CGFloat = 150

  var body: some View {
    Button {
      isSelected.toggle()
    } label: {
      Rectangle()
        .fill(.black)
        .roundedOutline()
        .frame(width: size, height: size)
        .overlay(alignment: .topTrailing) {
          SelectionIndicator(isSelected: isSelected)
        }
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  @Previewable @State var one = false
  @Previewable @State var two = false

  HStack {
    Card(isSelected: $one)
    Card(isSelected: $two)
  }
  .frame(
    maxWidth: .infinity,
    maxHeight: .infinity,
  )
}
#endif
