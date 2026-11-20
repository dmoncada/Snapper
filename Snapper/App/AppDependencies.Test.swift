import Logging
import SwiftData

struct TestDependencies: AppDependencies {
  let modelContainer: ModelContainer

  let apiClient: any ApiClient
  let previewPlayer: any PreviewPlaying
  let imageRecognizer: any ImageRecognizing
  let locationProvider: any LocationProviding
  let recordStoreLocator: any RecordStoreLocating
  let dateTimeProvider: any DateTimeProviding

  let searchViewModel: AlbumSearchViewModel
  let detailViewModel: AlbumDetailViewModel
  let historyViewModel: AlbumHistoryViewModel
  let locationCoordinator: AlbumLocationCaptureCoordinator

  init() {
    let searchContainer: ModelContainer
    let historyContainer: ModelContainer

    do {
      searchContainer = try SampleDataStore.makeContainer(named: "search")
      historyContainer = try SampleDataStore.makeContainer(named: "albums")
    } catch {
      fatalError("Unable to create schema.")
    }

    LoggingSystem.bootstrap({ _ in SwiftLogNoOpLogHandler() })

    modelContainer = historyContainer

    let searchClient: ApiClient = .stub(searchContainer)
    let historyClient: ApiClient = .stub(historyContainer)

    apiClient = historyClient

    previewPlayer = .null
    imageRecognizer = .null
    locationProvider = .null
    recordStoreLocator = .live

    dateTimeProvider = .stub(modelContainer)

    searchViewModel = .init(apiClient: searchClient, recognizer: imageRecognizer)
    detailViewModel = .init(apiClient: historyClient)
    historyViewModel = .init(context: historyContainer.mainContext)
    locationCoordinator = .init(locator: locationProvider)
  }
}
