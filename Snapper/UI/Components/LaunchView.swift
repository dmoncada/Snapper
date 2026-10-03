import SwiftUI

struct LaunchView: View {
  var body: some View {
    Text("MusicSnap")
      .fullBackground(.themePrimary)
      .font(.basteleurBold(.title))
      .foregroundStyle(.black)
  }
}

#Preview {
  LaunchView()
}
