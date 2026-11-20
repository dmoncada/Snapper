import Logging
import Sentry
import SentrySwiftLog
import SwiftData

struct LiveDependencies: AppDependencies {
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
    do {
      modelContainer = try SnapperStore.makeContainer()
    } catch {
      fatalError("Unable to create schema.")
    }

    if let location = modelContainer.mainContext.sqliteLocation {
      print(location)
    }

    Self.initLogging()

    apiClient = .live
    previewPlayer = .live
    imageRecognizer = .live
    locationProvider = .live
    recordStoreLocator = .live

    let logger1 = Logger(label: "\(Constants.appId).\(Features.search)")
    let logger2 = Logger(label: "\(Constants.appId).\(Features.detail)")
    let logger3 = Logger(label: "\(Constants.appId).\(Features.history)")

    searchViewModel = .init(logger: logger1, apiClient: apiClient, recognizer: imageRecognizer)
    detailViewModel = .init(logger: logger2, apiClient: apiClient)
    historyViewModel = .init(logger: logger3, context: modelContainer.mainContext)
    locationCoordinator = .init(locator: locationProvider)
  }

  private static func initLogging() {
    let sentryHandler = Self.initSentry()

    LoggingSystem.bootstrap { label in
      let consoleHandler = StreamLogHandler.standardOutput(label: label)

      var handlers: [LogHandler] = [consoleHandler]

      if let sentryHandler {
        handlers.append(sentryHandler)
      }

      return MultiplexLogHandler(handlers)
    }
  }

  private static func initSentry() -> SentryLogHandler? {
    guard let dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String
    else { return nil }

    SentrySDK.start { options in
      options.dsn = dsn
      options.enableLogs = true
    }

    var sentryHandler = SentryLogHandler(logLevel: .info)
    sentryHandler.metadata["app_version"] = "1.0.0"
    sentryHandler.metadata["environment"] = "development"

    return sentryHandler
  }
}
