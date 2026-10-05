import SwiftUI

struct LaunchView: View {
  var body: some View {
    Text("MusicSnap")
      .foregroundStyle(.themePrimaryInverted)
      .fullBackground(.themePrimary)
      .font(.basteleurBold(.title))
  }
}

#Preview {
  LaunchView()
}
