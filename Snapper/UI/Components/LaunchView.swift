import SwiftUI

struct LaunchView: View {
  var body: some View {
    Image(.musicSnap)
      .resizable()
      .scaledToFit()
      .padding(Padding.xxxl)
      .foregroundStyle(.themePrimary)
      .withFullBackground()
  }
}

#Preview {
  LaunchView()
}
