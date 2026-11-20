import SwiftData
import SwiftUI

struct SnapperAppShell: View {
  @Environment(\.scenePhase) private var phase
  @Environment(\.modelContext) private var context

  @Environment(AlbumLocationCaptureCoordinator.self) private var locationCoordinator

  var body: some View {
    TabView {
      Tab(.Search.title, systemImage: "house") {
        HomeView()
      }
      Tab(.History.title, systemImage: "clock") {
        HistoryView()
      }
      Tab(.Spatial.title, systemImage: "map") {
        AlbumMapView()
      }
      #if DEBUG && false
      Tab("Export", systemImage: "square.and.arrow.up") {
        SampleDataExportView()
      }
      #endif
    }
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
