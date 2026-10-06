import SwiftUI

struct LaunchView: View {
  var body: some View {
    Image(.musicSnap)
      .resizable()
      .scaledToFit()
      .padding(Padding.xxl)
      .foregroundStyle(.themePrimaryInverted)
      .fullBackground(.themePrimary)
  }
}

#Preview {
  LaunchView()
}
