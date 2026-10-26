import Logging
import Sentry
import SentrySwiftLog
import SwiftData

@MainActor
struct Dependencies {
  let modelContainer: ModelContainer

  let apiClient: any ApiClient
  let previewPlayer: any PreviewPlaying
  let imageRecognizer: any ImageRecognizing
  let locationProvider: any LocationProviding

  let searchViewModel: AlbumSearchViewModel
  let historyViewModel: AlbumHistoryViewModel
  let locationCoordinator: AlbumLocationCaptureCoordinator

  init() {
    modelContainer = Self.initContainer()

    if let location = modelContainer.mainContext.sqliteLocation {
      print(location)
    }

    apiClient = .live
    previewPlayer = .live
    imageRecognizer = .live
    locationProvider = .live

    Self.initLogging()

    let logger = Logger(label: Constants.appId)

    searchViewModel = AlbumSearchViewModel(
      logger: logger,
      apiClient: apiClient,
      recognizer: imageRecognizer,
    )

    historyViewModel = AlbumHistoryViewModel(context: modelContainer.mainContext)
    locationCoordinator = AlbumLocationCaptureCoordinator(locator: locationProvider)
  }

  private static func initContainer() -> ModelContainer {
    do {
      #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("-ui-testing-seed-albums") {
        return try SampleDataStore.makeContainer(limit: 2)
      }
      return try SnapperStore.makeContainer()
      #else
      return try SnapperStore.makeContainer()
      #endif
    } catch {
      fatalError("Unable to create schema.")
    }
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
