import SwiftUI

struct SchemeSelectionView: View {
  @Binding var selection: ColorSchemePreference

  var body: some View {
    List {
      ForEach(ColorSchemePreference.allCases) { option in
        Button {
          selection = option
        } label: {
          HStack {
            Text(option.displayName)
              .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "checkmark")
              .opacity(selection == option ? 1 : 0)
          }
        }
        // .foregroundStyle(.themePrimary)
      }
    }
  }
}

#if DEBUG
#Preview {
  @Previewable @State var selection: ColorSchemePreference = .dark

  SchemeSelectionView(selection: $selection)
    .preferredColorScheme(selection.colorScheme)
}
#endif
