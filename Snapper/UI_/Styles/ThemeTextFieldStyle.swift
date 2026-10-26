import SwiftUI

struct SearchTextFieldStyle: TextFieldStyle {
  @Binding var text: String

  var isFocused: Bool

  func _body(
    configuration: TextField<Self._Label>
  ) -> some View {
    configuration
      .safeAreaInset(edge: .leading) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
      }
      .safeAreaInset(edge: .trailing) {
        Button("Clear", systemImage: "xmark.circle.fill") {
          text = ""
        }
        .labelStyle(.iconOnly)
        .foregroundStyle(.secondary)
        .opacity(text.isEmpty ? 0 : 1)
      }
      .padding()
      .roundedOutline(lineWidth: isFocused ? 2 : 1)
  }
}

extension TextFieldStyle where Self == SearchTextFieldStyle {
  static func searchField(
    text: Binding<String>,
    isFocused: Bool,
  ) -> Self {
    Self(
      text: text,
      isFocused: isFocused,
    )
  }
}

private struct SearchFieldModifier: ViewModifier {
  @Binding var text: String

  var isFocused: Bool

  func body(content: Content) -> some View {
    content
      .safeAreaInset(edge: .leading) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
      }
      .safeAreaInset(edge: .trailing) {
        Button("Clear", systemImage: "xmark.circle.fill") {
          text = ""
        }
        .labelStyle(.iconOnly)
        .foregroundStyle(.secondary)
        .opacity(text.isEmpty ? 0 : 1)
      }
      .padding()
      .roundedOutline(lineWidth: isFocused ? 2 : 1)
  }
}

extension View {
  func searchField(
    text: Binding<String>,
    isFocused: Bool,
  ) -> some View {
    modifier(
      SearchFieldModifier(
        text: text,
        isFocused: isFocused,
      )
    )
  }
}

struct WithColorSchemes<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    VStack(spacing: 0) {
      content
        .frame(maxWidth: .infinity)
        .background(.themePrimary)
        .environment(\.colorScheme, .light)

      content
        .frame(maxWidth: .infinity)
        .background(.themePrimary)
        .environment(\.colorScheme, .dark)
    }
  }
}

#if DEBUG
private struct TestSearchField: View {
  @FocusState private var isFocused: Bool

  @State private var query = ""

  var body: some View {
    VStack(spacing: 20) {
      TextField(
        "Some",
        text: $query,
        prompt: Text("Or search by artist, album"),
      )
      .textFieldStyle(
        .searchField(
          text: $query,
          isFocused: isFocused,
        )
      )
      .focused($isFocused)

      HStack {
        Button(isFocused ? "Unfocus" : "Focus") {
          isFocused.toggle()
        }

        Button("Insert query") {
          query = "Abbey Road"
        }
      }
      .buttonStyle(.borderedProminent)
      .foregroundStyle(.themePrimary)
    }
    .padding()
  }
}

#Preview("Light & Dark") {
  WithColorSchemes {
    TestSearchField()
  }
}
#endif
