import SwiftUI

struct SheetDestinationModifier: ViewModifier {
  @AppStorage(.storageKeys.colorScheme)
  private var preference: ColorSchemePreference = .system

  @Environment(\.colorScheme) private var systemScheme

  let item: Binding<SheetDestination?>

  func body(content: Content) -> some View {
    content
      .sheet(item: item) { destination in
        Group {
          switch destination {
          case .settings:
            SettingsSheet()
          }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(preference.colorScheme ?? systemScheme)
      }
  }
}

extension View {
  func withSheetDestination(_ item: Binding<SheetDestination?>) -> some View {
    modifier(SheetDestinationModifier(item: item))
  }
}

#Preview {
  @Previewable @AppStorage(.storageKeys.colorScheme)
  var preference: ColorSchemePreference = .system

  @Previewable @State var sheetItem: SheetDestination?

  VStack(spacing: 16) {
    Button("Show settings") {
      sheetItem = .settings
    }
  }
  .withSheetDestination($sheetItem)
  .preferredColorScheme(preference.colorScheme)
}
