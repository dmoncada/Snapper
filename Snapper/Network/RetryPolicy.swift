import Foundation

nonisolated struct RetryPolicy: Sendable {
  let maximumRetries: Int
  let initialBackoff: Duration
  let backoffMultiplier: Int
  let retryableHttpStatusCodes: Set<Int>
  let retryableUrlErrorCodes: Set<URLError.Code>

  init(
    maximumRetries: Int = 3,
    initialBackoff: Duration = .milliseconds(500),
    backoffMultiplier: Int = 2,
    retryableHttpStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504],
    retryableUrlErrorCodes: Set<URLError.Code> = [
      .timedOut,
      .cannotFindHost,
      .cannotConnectToHost,
      .networkConnectionLost,
      .dnsLookupFailed,
      .notConnectedToInternet,
    ]
  ) {
    precondition(maximumRetries >= 0, "maximumRetries cannot be negative")
    precondition(initialBackoff >= .zero, "initialBackoff cannot be negative")
    precondition(backoffMultiplier >= 1, "backoffMultiplier must be at least one")

    self.maximumRetries = maximumRetries
    self.initialBackoff = initialBackoff
    self.backoffMultiplier = backoffMultiplier
    self.retryableHttpStatusCodes = retryableHttpStatusCodes
    self.retryableUrlErrorCodes = retryableUrlErrorCodes
  }

  func delay(beforeRetry retryNumber: Int) -> Duration {
    let exponent = max(0, retryNumber - 1)
    let multiplier = (0 ..< exponent).reduce(1) { result, _ in
      result * backoffMultiplier
    }
    return initialBackoff * multiplier
  }

  func delay(beforeRetry retryNumber: Int, retryAfter: String?) -> Duration {
    guard
      let retryAfter,
      let seconds = Int(retryAfter.trimmingCharacters(in: .whitespacesAndNewlines)),
      seconds >= 0
    else {
      return delay(beforeRetry: retryNumber)
    }

    return .seconds(seconds)
  }

  func shouldRetry(_ error: any Error) -> Bool {
    guard let urlError = error as? URLError else {
      return false
    }

    return retryableUrlErrorCodes.contains(urlError.code)
  }
}
