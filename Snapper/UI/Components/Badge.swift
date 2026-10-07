import SwiftUI

struct BadgeStyleModifier: ViewModifier {
  let isActive: Bool

  func body(content: Content) -> some View {
    content
      .padding(Padding.md)
      .font(.sligoilMicroBold(.caption2))
      .foregroundStyle(
        isActive
          ? .themePrimary
          : .themePrimaryInverted
      )
      .background {
        if isActive {
          RoundedRectangle(cornerRadius: Radius.md)
            .fill(.tint)
        } else {
          RoundedRectangle(cornerRadius: Radius.md)
            .stroke(.themePrimaryInverted)
        }
      }
  }
}

struct BadgeToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .badgeStyle(isActive: configuration.isOn)
      .onTapGesture {
        configuration.isOn.toggle()
      }
  }
}

extension View {
  func badgeStyle(isActive: Bool = false) -> some View {
    modifier(BadgeStyleModifier(isActive: isActive))
  }
}

extension ToggleStyle where Self == BadgeToggleStyle {
  static var badge: Self {
    Self()
  }
}

#if DEBUG
private struct TestBadge: View {
  @State private var isOn1 = false
  @State private var isOn2 = false

  var body: some View {
    VStack {
      Text("Badge")
        .badgeStyle()

      Toggle("Toggle", isOn: $isOn1)
        .toggleStyle(.badge)

      Toggle("Tinted toggle", isOn: $isOn2)
        .toggleStyle(.badge)
        .tint(.blue)
    }
  }
}

#Preview {
  VStack(spacing: 0) {
    TestBadge()
      .frame(height: 200)
      .frame(maxWidth: .infinity)
      .background(.themePrimary)
      .environment(\.colorScheme, .light)

    TestBadge()
      .frame(height: 200)
      .frame(maxWidth: .infinity)
      .background(.themePrimary)
      .environment(\.colorScheme, .dark)
  }
}
#endif
