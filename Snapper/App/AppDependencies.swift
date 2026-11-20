import SwiftData

protocol AppDependencies {
  var modelContainer: ModelContainer { get }

  var apiClient: any ApiClient { get }
  var previewPlayer: any PreviewPlaying { get }
  var imageRecognizer: any ImageRecognizing { get }
  var locationProvider: any LocationProviding { get }
  var recordStoreLocator: any RecordStoreLocating { get }
  var dateTimeProvider: any DateTimeProviding { get }

  var searchViewModel: AlbumSearchViewModel { get }
  var detailViewModel: AlbumDetailViewModel { get }
  var historyViewModel: AlbumHistoryViewModel { get }
  var locationCoordinator: AlbumLocationCaptureCoordinator { get }
}
