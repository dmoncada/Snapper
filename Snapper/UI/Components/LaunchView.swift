import SwiftUI

struct LaunchView: View {
  var body: some View {
    Image(.musicSnap)
      .resizable()
      .scaledToFit()
      .padding(Padding.xxl)
      .withFullBackground()
  }
}

#Preview {
  LaunchView()
}
