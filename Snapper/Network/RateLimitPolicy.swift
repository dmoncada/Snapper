nonisolated struct RateLimitPolicy: Sendable {
  let maximumRequests: Int
  let window: Duration

  init(maximumRequests: Int = 20, window: Duration = .seconds(60)) {
    precondition(maximumRequests > 0, "maximumRequests must be greater than zero")
    precondition(window > .zero, "window must be greater than zero")

    self.maximumRequests = maximumRequests
    self.window = window
  }
}
