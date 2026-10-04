import AVFoundation
import SwiftData
import SwiftUI

struct SnapperAppShell: View {
  @AppStorage(.storageKeys.colorScheme)
  private var preference: ColorSchemePreference = .system

  @Environment(\.scenePhase) private var phase
  @Environment(\.modelContext) private var context

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
    .preferredColorScheme(preference.colorScheme)
    .environment(locationCapture)
    .environment(PreviewPlayer())
    .environment(router)
    .task {
      locationCapture.resumePending(in: context)
    }
    .onChange(of: phase) { _, next in
      if next == .active {
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
