import Foundation

actor RateLimiter {
  private let policy: RateLimitPolicy
  private let clock = ContinuousClock()
  private var requestTimes: [ContinuousClock.Instant] = []

  init(policy: RateLimitPolicy = RateLimitPolicy()) {
    self.policy = policy
  }

  func acquirePermission() async throws {
    while true {
      try Task.checkCancellation()

      let now = clock.now
      requestTimes.removeAll {
        $0.duration(to: now) >= policy.window
      }

      if requestTimes.count < policy.maximumRequests {
        requestTimes.append(now)
        return
      }

      guard let oldestRequest = requestTimes.first else {
        continue
      }

      let nextAvailableTime = oldestRequest.advanced(by: policy.window)
      try await clock.sleep(until: nextAvailableTime, tolerance: .milliseconds(50))
    }
  }
}
