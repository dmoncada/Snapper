import SwiftUI

struct FavoriteIconButton: View {
  @Binding var isFavorite: Bool

  var body: some View {
    Button {
      isFavorite.toggle()
    } label: {
      Group {
        if isFavorite {
          Image(systemName: "heart.fill")
        } else {
          Image(systemName: "heart")
        }
      }
    }
    .favoriteIconStyle(isFavorite: isFavorite)
    .buttonStyle(.scale)
  }
}

private struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.9 : 1)
      .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == ScaleButtonStyle {
  static var scale: Self { Self() }
}

struct FavoriteIconStyle: ViewModifier {
  let isFavorite: Bool

  func body(content: Content) -> some View {
    content
      .symbolEffect(.bounce.up, options: .speed(2), value: isFavorite)
      .foregroundStyle(.accent)
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

    FavoriteIconButton(isFavorite: $isFavorite)
      .border(.red)
  }
}
#endif
