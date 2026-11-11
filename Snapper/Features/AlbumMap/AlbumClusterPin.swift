import SwiftUI

struct AlbumClusterPin: View {
  let count: Int
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(count, format: .number)
        .padding(Padding.xl)
        .font(.gillSans(.headline))
        .foregroundStyle(.themeOffWhite)
        .background(.tint, in: .circle)
    }
    .buttonStyle(.plain)
  }
}

#if DEBUG
#Preview {
  AlbumClusterPin(count: 5) {}
    .padding()
}
#endif
