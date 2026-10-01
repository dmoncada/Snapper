import SwiftUI

struct LargeButton: View {
  let title: String
  let action: () -> Void

  init(
    _ title: String,
    action: @escaping () -> Void,
  ) {
    self.title = title
    self.action = action
  }

  var body: some View {
    Button(title, action: action)
      .buttonStyle(.large)
  }
}

struct LargeButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.basteleurBold(.title2))
      .foregroundStyle(.themePrimaryInverted)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(.themeSeafoam)
      .roundedOutline()
      .opacity(configuration.isPressed ? 0.7 : 1)
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
  }
}

extension ButtonStyle where Self == LargeButtonStyle {
  static var large: Self { LargeButtonStyle() }
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
