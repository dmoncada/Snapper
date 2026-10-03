import AVFoundation
import SwiftData
import SwiftUI

struct SnapperAppShell: View {
  @AppStorage(.storageKeys.colorScheme)
  private var preference: ColorSchemePreference = .system

  @Environment(\.modelContext) private var context
  @Environment(\.scenePhase) private var scenePhase

  @State private var router = Router()
  @State private var locationCapture = AlbumLocationCaptureCoordinator()

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
    .withAlertDestination($router.alertItem)
    .onAppear { AVPlayer.isObservationEnabled = true }
    .preferredColorScheme(preference.colorScheme)
    .environment(locationCapture)
    .environment(PreviewPlayer())
    .environment(router)
    .task {
      locationCapture.resumePending(in: context)
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active {
        locationCapture.resumePending(in: context)
      }
    }
  }
}

#if DEBUG
#Preview(traits: .withSampleData) {
  SnapperAppShell()
}
#endif
