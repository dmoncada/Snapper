import Logging
import SwiftData

@MainActor
@Observable
final class AppState {
  let modelContainer: ModelContainer

  let apiClient: any ApiClient
  let previewPlayer: any PreviewPlaying
  let imageRecognizer: any ImageRecognizing
  let locationProvider: any LocationProviding
  let recordStoreLocator: any RecordStoreLocating

  let searchViewModel: AlbumSearchViewModel
  let detailViewModel: AlbumDetailViewModel
  let historyViewModel: AlbumHistoryViewModel
  let locationCoordinator: AlbumLocationCaptureCoordinator

  init() {
    let dependencies: any AppDependencies

    if Application.isTest {
      dependencies = TestDependencies()
    } else {
      dependencies = LiveDependencies()
    }

    modelContainer = dependencies.modelContainer

    apiClient = dependencies.apiClient
    previewPlayer = dependencies.previewPlayer
    imageRecognizer = dependencies.imageRecognizer
    locationProvider = dependencies.locationProvider
    recordStoreLocator = dependencies.recordStoreLocator

    searchViewModel = dependencies.searchViewModel
    detailViewModel = dependencies.detailViewModel
    historyViewModel = dependencies.historyViewModel
    locationCoordinator = dependencies.locationCoordinator
  }
}
