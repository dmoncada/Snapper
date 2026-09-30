import AVFoundation
import SwiftData
import SwiftUI

struct SnapperAppShell: View {
  @AppStorage(.storageKeys.colorScheme)
  private var preference: ColorSchemePreference = .system

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
    .onAppear { AVPlayer.isObservationEnabled = true }
    .preferredColorScheme(preference.colorScheme)
    .modelContainer(for: AlbumEntry.self)
    .environment(LocationManager())
    .environment(PreviewPlayer())
    .environment(router)
  }
}

#Preview {
  SnapperAppShell()
}
