import SwiftUI

struct SettingsSheet: View {
  var body: some View {
    NavigationStack {
      SettingsView()
        .presentationDetents([.medium, .large])
        .withToolbarTitle(.Settings.title, style: .principal)
        .withCloseButton()
    }
  }
}

private struct SettingsView: View {
  @AppStorage(.storageKeys.colorScheme)
  private var preference: ColorSchemePreference = .system

  @AppStorage(.storageKeys.openFirstResult)
  private var openFirstResult = false

  var body: some View {
    Form {
      #if false
      // When using the below, picking an item will immediately return to the nav. root.
      Section {
        Picker("Theme", selection: $preference) {
          ForEach(ColorSchemePreference.allCases) { option in
            Text(option.displayName)
              .tag(option)
          }
          .containerBackground(.clear, for: .navigation)
          .scrollContentBackground(.hidden)
        }
        .pickerStyle(.navigationLink)
      } footer: {
        Text("Controls the app's theme preference.")
      }
      #endif

      Section {
        NavigationLink {
          SchemeSelectionView(selection: $preference)
            .withToolbarTitle(.Settings.themeTitle, style: .principal)
            .containerBackground(.clear, for: .navigation)
            .scrollContentBackground(.hidden)
        } label: {
          LabeledContent(.Settings.themeTitle) {
            Text(preference.resource)
          }
        }
      } footer: {
        Text(.Settings.themeFooter)
      }

      Section {
        Toggle("Open first barcode result", isOn: $openFirstResult)
      } footer: {
        Text(
          """
          Show album details directly after scanning a barcode. \
          You can review other results before adding.
          """
        )
      }

      Section {
        Button {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
        } label: {
          LabeledContent("Location") {
            Image(systemName: "chevron.right")
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
        .frame(
          maxWidth: .infinity,
          maxHeight: .infinity,
          alignment: .center,
        )
        .listRowBackground(Color.clear)
        .font(.caption)
    }
  }
}

#if DEBUG
#Preview {
  @Previewable @AppStorage(.storageKeys.colorScheme)
  var preference: ColorSchemePreference = .system

  @Previewable @Environment(\.colorScheme) var systemScheme

  @Previewable @State var isPresented = true

  Button("Open settings") {
    isPresented = true
  }
  .sheet(isPresented: $isPresented) {
    SettingsSheet()
      .preferredColorScheme(preference.colorScheme ?? systemScheme)
  }
  .preferredColorScheme(preference.colorScheme)
  .buttonStyle(.borderedProminent)
}
#endif
