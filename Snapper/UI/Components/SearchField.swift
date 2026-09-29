import SwiftUI

struct SearchField: View {
  @Environment(\.colorScheme) private var scheme

  @Binding var text: String

  private let placeholder: String
  private let leadingPadding = Padding.xl

  init(text: Binding<String>, placeholder: String = "") {
    self._text = text
    self.placeholder = placeholder
  }

  var body: some View {
    let opacity = scheme == .light ? 0.25 : 0.5
    let fadedStyle = AnyShapeStyle(.themePrimaryInverted.opacity(0.25))

    TextField(text: $text) {
      Text(placeholder)
        .foregroundStyle(fadedStyle)
    }
    .autocorrectionDisabled(true)
    .textInputAutocapitalization(.never)
    .safeAreaInset(edge: .leading) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(fadedStyle)
    }
    .safeAreaInset(edge: .trailing) {
      if text.count > 0 {
        Button("Clear", systemImage: "xmark.circle") {
          text = ""
        }
        .foregroundStyle(fadedStyle)
        .labelStyle(.iconOnly)
      }
    }
    .padding()
    .font(.sligoilMicro(.body))
    .foregroundStyle(.themePrimaryInverted)
    .background(.themeSeafoam.opacity(opacity))
    .roundedOutline()
  }
}

#Preview {
  @Previewable @State var text = "Filled"

  let placeholder = "Placeholder..."

  VStack(spacing: 0) {
    VStack {
      SearchField(text: .constant(""), placeholder: placeholder)
      SearchField(text: $text, placeholder: placeholder)
    }
    .padding()
    .frame(height: 200)
    .background(.themePrimary)
    .colorScheme(.light)

    VStack {
      SearchField(text: .constant(""), placeholder: placeholder)
      SearchField(text: $text, placeholder: placeholder)
    }
    .padding()
    .frame(height: 200)
    .background(.themePrimary)
    .colorScheme(.dark)
  }
}
