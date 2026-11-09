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
      .foregroundStyle(
        .themePrimary,
        .themeSeparator,
      )
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
    }
    .padding()
  }
}

#Preview {
  WithColorSchemes {
    TestSearchField()
  }
}
#endif
