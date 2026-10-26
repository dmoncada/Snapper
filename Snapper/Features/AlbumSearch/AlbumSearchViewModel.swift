import Logging
import SwiftUI

@MainActor
@Observable
final class AlbumSearchViewModel {
  enum SearchKind {
    case term(String)
    case barcode(String)
  }

  enum State: Equatable {
    case ready
    case searching
    case detecting
    case cancelled
    case success([Album])
    case failure(SearchError)
  }

  private(set) var state: State = .ready

  private let logger: Logger?
  private let apiClient: any ApiClient
  private let recognizer: any ImageRecognizing

  init(
    logger: Logger? = nil,
    apiClient: any ApiClient = .null,
    recognizer: any ImageRecognizing = .null,
  ) {
    self.logger = logger
    self.apiClient = apiClient
    self.recognizer = recognizer
  }

  func search(
    by kind: SearchKind,
    debounceDuration: Duration = .seconds(1),
    limit: Int = 10,
  ) async {
    var term: String?
    var barcode: String?

    switch kind {
    case .term(let value): term = value
    case .barcode(let value): barcode = value
    }

    if term.isNilOrEmpty && barcode.isNilOrEmpty {
      state = .ready
      return
    }

    state = .searching

    do {
      try await Task.sleep(for: debounceDuration)
      try Task.checkCancellation()

      let candidates = try await apiClient.searchAlbums(term: term, barcode: barcode, limit: limit)
      let results = candidates.map { Album(dto: $0) }

      logger?.info("Found: \(results.count) albums for: '\(term ?? barcode ?? "nil")'")

      state = .success(results)
    } catch is CancellationError {
      // state = .cancelled
    } catch {
      state = .failure(.generic)
    }
  }

  func detect(in data: Data, limit: Int = 10) async {
    state = .detecting

    do {
      let result = try await recognizer.recognize(in: data)
      try Task.checkCancellation()

      guard let barcode = result.barcode else {
        state = .failure(.detection)
        return
      }

      return await search(by: .barcode(barcode), debounceDuration: .zero, limit: limit)
    } catch is CancellationError {
      // state = .cancelled
    } catch {
      state = .failure(.generic)
    }
  }
}

enum SearchError: Error {
  case generic
  case detection

  var message: LocalizedStringResource {
    switch self {
    case .generic: "search.error.generic"
    case .detection: "search.error.detection"
    }
  }
}

extension Optional where Wrapped == String {
  fileprivate var isNilOrEmpty: Bool {
    self?.isEmpty != false
  }
}
