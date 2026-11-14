import Logging
import Sentry
import SentrySwiftLog
import SwiftData

protocol AppDependencies {
  var modelContainer: ModelContainer { get }

  var apiClient: any ApiClient { get }
  var previewPlayer: any PreviewPlaying { get }
  var imageRecognizer: any ImageRecognizing { get }
  var locationProvider: any LocationProviding { get }
  var recordStoreLocator: any RecordStoreLocating { get }
  var dateTimeProvider: any DateTimeProviding { get }
}

struct LiveDependencies: AppDependencies {
  let modelContainer: ModelContainer

  let apiClient: any ApiClient
  let previewPlayer: any PreviewPlaying
  let imageRecognizer: any ImageRecognizing
  let locationProvider: any LocationProviding
  let recordStoreLocator: any RecordStoreLocating
  let dateTimeProvider: any DateTimeProviding

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
    dateTimeProvider = .live
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

struct TestDependencies: AppDependencies {
  let modelContainer: ModelContainer

  let apiClient: any ApiClient
  let previewPlayer: any PreviewPlaying
  let imageRecognizer: any ImageRecognizing
  let locationProvider: any LocationProviding
  let recordStoreLocator: any RecordStoreLocating
  let dateTimeProvider: any DateTimeProviding

  init() {
    do {
      modelContainer = try SampleDataStore.makeContainer()
    } catch {
      fatalError("Unable to create schema.")
    }

    LoggingSystem.bootstrap({ _ in SwiftLogNoOpLogHandler() })

    apiClient = .stub(modelContainer)

    previewPlayer = .null
    imageRecognizer = .null
    locationProvider = .null
    recordStoreLocator = .null

    dateTimeProvider = .stub(modelContainer)
  }
}
