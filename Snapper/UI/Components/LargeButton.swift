import SwiftUI

struct LargeButton: View {
  let title: String
  let action: () -> Void

  init(_ title: String, action: @escaping () -> Void) {
    self.title = title
    self.action = action
  }

  var body: some View {
    Button(title, action: action)
      .font(.basteleurBold(.title2))
      .foregroundStyle(.themePrimaryInverted)
      .background(.themeSeafoam)
      .buttonStyle(.fullWidth)
      .roundedOutline()
  }
}

#Preview {
  VStack(spacing: 0) {
    LargeButton("Light") {}
      .padding()
      .frame(height: 150)
      .background(.themePrimary)

    LargeButton("Dark") {}
      .padding()
      .frame(height: 150)
      .background(.themePrimary)
      .colorScheme(.dark)
  }
}
