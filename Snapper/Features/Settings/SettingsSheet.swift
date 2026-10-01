import SwiftUI

struct SettingsSheet: View {
  @AppStorage(.storageKeys.colorScheme)
  private var preference: ColorSchemePreference = .system

  var body: some View {
    NavigationStack {
      Form {
        Section {
          NavigationLink {
            SchemeSelectionView(selection: $preference)
              .navigationTitle("Theme")
          } label: {
            HStack {
              Text("Theme")
                .frame(maxWidth: .infinity, alignment: .leading)

              Text(preference.displayName)
              // .foregroundStyle(.themeSecondary)
            }
          }
        } footer: {
          Text("Controls the app's theme preference.")
        }
      }
      .navigationToolbar(title: "Settings")
    }
  }
}

#if DEBUG
#Preview("View") {
  @Previewable @AppStorage(.storageKeys.colorScheme)
  var preference: ColorSchemePreference = .system

  SettingsSheet()
    .preferredColorScheme(preference.colorScheme)
}

#Preview("Sheet") {
  @Previewable @AppStorage(.storageKeys.colorScheme)
  var preference: ColorSchemePreference = .system

  @Previewable @State var router = Router()

  Button("Open settings") {
    router.sheetItem = .settings
  }
  .buttonStyle(.borderedProminent)
  .withSheetDestination($router.sheetItem)
  .preferredColorScheme(preference.colorScheme)
}
#endif
