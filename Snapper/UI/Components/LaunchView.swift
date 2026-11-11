import SwiftUI

struct LaunchView: View {
  var body: some View {
    Image(.musicSnap)
      .resizable()
      .scaledToFit()
      .padding(Padding.xxxl)
      .withFullBackground()
  }
}

#Preview {
  LaunchView()
}
