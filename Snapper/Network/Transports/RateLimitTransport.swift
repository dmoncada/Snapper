import Foundation

nonisolated struct RateLimitTransport: HttpTransport {
  private let transport: any HttpTransport
  private let rateLimiter: RateLimiter

  init(
    transport: any HttpTransport,
    rateLimiter: RateLimiter
  ) {
    self.transport = transport
    self.rateLimiter = rateLimiter
  }

  func send(_ request: URLRequest) async throws -> HttpResponse {
    try await rateLimiter.acquirePermission()
    return try await transport.send(request)
  }
}

extension HttpTransport {
  nonisolated func withRateLimit(
    policy: RateLimitPolicy = RateLimitPolicy()
  ) -> RateLimitTransport {
    RateLimitTransport(
      transport: self,
      rateLimiter: RateLimiter(policy: policy)
    )
  }
}
