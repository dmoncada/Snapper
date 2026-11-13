import SwiftUI

struct FavoriteIconToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      Image(systemName: "heart")
        .symbolVariant(configuration.isOn ? .fill : .none)
    }
    .favoriteIconStyle(isFavorite: configuration.isOn)
    .buttonStyle(.pressedScale(0.9))
  }
}

struct FavoriteIconStyle: ViewModifier {
  let isFavorite: Bool

  func body(content: Content) -> some View {
    content
      .symbolEffect(
        .bounce.up,
        options: .speed(2),
        value: isFavorite,
      )
  }
}

extension ToggleStyle where Self == FavoriteIconToggleStyle {
  static var favoriteIcon: Self {
    Self()
  }
}

extension View {
  func favoriteIconStyle(isFavorite: Bool) -> some View {
    modifier(FavoriteIconStyle(isFavorite: isFavorite))
  }
}

#if DEBUG
#Preview {
  @Previewable @State var isFavorite = false

  VStack(spacing: 16) {
    Image(systemName: "heart.fill")
      .favoriteIconStyle(isFavorite: isFavorite)
      .opacity(isFavorite ? 1 : 0)
      .border(.red)

    Toggle("Favorite", isOn: $isFavorite)
      .toggleStyle(.favoriteIcon)
      .border(.red)
  }
  .foregroundStyle(.accent)
}
#endif
