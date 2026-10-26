import SwiftUI

struct Icon: View {
  init(
    systemName: String,
    size: CGFloat = 20,
  ) {
    self.systemName = systemName
    self.size = size
  }

  private let systemName: String
  private let size: CGFloat

  var body: some View {
    Image(systemName: systemName)
      .resizable()
      .scaledToFill()
      .frame(width: size, height: size)
  }
}

struct FavoriteIconButton: View {
  @Binding var isFavorite: Bool

  var body: some View {
    Button {
      isFavorite.toggle()
    } label: {
      Group {
        if isFavorite {
          Image(systemName: "star.fill")
        } else {
          Image(systemName: "star")
        }
      }
      .scaleEffect(1.25)
    }
    .symbolEffect(.bounce.up, options: .speed(2), value: isFavorite)
    .foregroundStyle(.accent)
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
  static var scale: ScaleButtonStyle {
    ScaleButtonStyle()
  }
}

#if DEBUG
#Preview {
  @Previewable @State var isFavorite = false

  FavoriteIconButton(isFavorite: $isFavorite)

  /*
  ForEach([40, 30, 20], id: \.self) { size in
    Icon(systemName: "star.fill", size: size)
      .foregroundStyle(.accent)
  }
   */
}
#endif
