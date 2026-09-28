import SwiftData
import SwiftUI

struct SnapperAppShell: View {
  @AppStorage(.storageKeys.colorScheme)
  private var preference: ColorSchemePreference = .system

  @State private var locator = LocationManager()
  @State private var router = Router()

  var body: some View {
    TabView {
      Tab("Home", systemImage: "house") {
        HomeView()
      }
      Tab("History", systemImage: "clock") {
        HistoryView()
      }
    }
    .withSheetDestination($router.sheetItem)
    // .task { await locator.requestPermission() }
    .preferredColorScheme(preference.colorScheme)
    .modelContainer(for: AlbumEntry.self)
    .environment(locator)
    .environment(router)
  }
}

#Preview {
  SnapperAppShell()
}
