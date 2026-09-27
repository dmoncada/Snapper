import SwiftUI

struct SearchField: View {
  @Environment(\.colorScheme) private var scheme

  @Binding var text: String

  let placeholder: String

  init(
    text: Binding<String>,
    placeholder: String = ""
  ) {
    self._text = text
    self.placeholder = placeholder
  }

  var body: some View {
    ZStack(alignment: .leading) {
      TextField("", text: $text)
        .autocorrectionDisabled(true)
        .textInputAutocapitalization(.never)
        .padding(.leading, Padding.xl)
        .padding(.vertical, Padding.xl)
        .font(.libreCaslonTextBold(.callout))
        .foregroundStyle(.themePrimaryInverted)
        .background(
          .themeSeafoam.opacity(
            scheme == .light
              ? 0.25
              : 0.75
          )
        )
        .roundedOutline()

      if text.isEmpty {
        Text(placeholder)
          .allowsHitTesting(false)
          .font(.libreCaslonTextBold(.callout))
          .foregroundStyle(.themePrimaryInverted.opacity(0.5))
          .padding(.leading, Padding.xl)
      }
    }
  }
}

#Preview {
  let placeholder = "Placeholder..."

  VStack(spacing: 0) {
    VStack {
      SearchField(text: .constant(""), placeholder: placeholder)
      SearchField(text: .constant("Filled"), placeholder: placeholder)
    }
    .padding()
    .frame(height: 200)
    .background(.themePrimary)
    .colorScheme(.light)

    VStack {
      SearchField(text: .constant(""), placeholder: placeholder)
      SearchField(text: .constant("Filled"), placeholder: placeholder)
    }
    .padding()
    .frame(height: 200)
    .background(.themePrimary)
    .colorScheme(.dark)
  }
}
