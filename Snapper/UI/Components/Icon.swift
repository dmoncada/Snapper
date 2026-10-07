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

#if DEBUG
#Preview {
  ForEach([40, 30, 20], id: \.self) { size in
    Icon(systemName: "star.fill", size: size)
      .foregroundStyle(.accent)
  }
}
#endif
