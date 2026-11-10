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
  let dateTimeProvider: any DateTimeProviding

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
    dateTimeProvider = dependencies.dateTimeProvider

    let logger1 = Logger(label: "\(Constants.appId).\(Features.search)")
    let logger2 = Logger(label: "\(Constants.appId).\(Features.detail)")
    let logger3 = Logger(label: "\(Constants.appId).\(Features.history)")

    searchViewModel = .init(logger: logger1, apiClient: apiClient, recognizer: imageRecognizer)
    detailViewModel = .init(logger: logger2, apiClient: apiClient)
    historyViewModel = .init(logger: logger3, context: modelContainer.mainContext)
    locationCoordinator = .init(locator: locationProvider)
  }
}
