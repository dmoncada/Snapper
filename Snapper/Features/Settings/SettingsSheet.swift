import SwiftUI

struct SettingsSheet: View {
  @AppStorage(.storageKeys.colorScheme)
  private var preference: ColorSchemePreference = .system

  @Environment(\.dismiss) private var dismiss

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
            }
          }
        } footer: {
          Text("Controls the app's theme preference.")
        }

        Section {
          Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(url)
            }
          } label: {
            HStack {
              Text("Location")
              Spacer()
              Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
            }
          }
          .buttonStyle(.plain)
        } footer: {
          Text(
            """
            Grant permission to access the device location in Settings, \
            to allow capturing the approximate location when adding an album.
            """
          )
        }

        Text("Made for the ❤️ of 🎵 in 🇲🇽")
          .frame(maxWidth: .infinity, alignment: .trailing)
          .listRowBackground(Color.clear)
      }
      .navigationToolbar(title: "Settings") {
        dismiss()
      }
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
