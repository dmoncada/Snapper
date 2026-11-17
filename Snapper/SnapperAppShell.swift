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
      Tab("Spatial", systemImage: "map") {
        AlbumMapView()
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
    .onChange(of: phase, initial: true) { _, next in
      switch next {
      case .active:
        locationCoordinator.resumePending(in: context)

      case .inactive:
        break
      case .background:
        break
      @unknown default:
        break
      }
    }
  }
}
