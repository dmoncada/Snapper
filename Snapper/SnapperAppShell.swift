import AVFoundation
import SwiftData
import SwiftUI

struct SnapperAppShell: View {
  @AppStorage(.storageKeys.colorScheme)
  private var preference: ColorSchemePreference = .system

  @Environment(\.scenePhase) private var phase
  @Environment(\.modelContext) private var context

  @Environment(AlbumLocationCaptureCoordinator.self) private var locationCoordinator

  @State private var router = Router()

  var body: some View {
    TabView {
      Tab("Home", systemImage: "house") {
        HomeView()
      }
      Tab("History", systemImage: "clock") {
        HistoryView()
      }
      #if DEBUG
      Tab("Export", systemImage: "square.and.arrow.up") {
        SampleDataExportView()
      }
      #endif
    }
    .withSheetDestination($router.sheetItem)
    .withAlertDestination($router.alertItem)
    .preferredColorScheme(preference.colorScheme)
    .environment(router)
    .task {
      locationCoordinator.resumePending(in: context)
    }
    .onChange(of: phase) { _, next in
      if next == .active {
        locationCoordinator.resumePending(in: context)
      }
    }
  }
}

#if DEBUG
#Preview(traits: .withSampleData) {
  SnapperAppShell()
    .environment(AlbumSearchViewModel())
    .environment(AlbumLocationCaptureCoordinator())
}
#endif
