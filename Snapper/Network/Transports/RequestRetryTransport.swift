import Foundation

nonisolated struct RequestRetryTransport: HttpTransport {
  private let transport: any HttpTransport
  private let policy: RetryPolicy

  init(
    transport: any HttpTransport,
    policy: RetryPolicy = RetryPolicy()
  ) {
    self.transport = transport
    self.policy = policy
  }

  func send(_ request: URLRequest) async throws -> HttpResponse {
    for attempt in 0 ... policy.maximumRetries {
      try Task.checkCancellation()

      do {
        let response = try await transport.send(request)

        let shouldRetry = policy.retryableHttpStatusCodes.contains(response.response.statusCode)
        guard shouldRetry, attempt < policy.maximumRetries else { return response }

        let retryNumber = attempt + 1
        let retryAfter = response.response.value(forHTTPHeaderField: "Retry-After")
        try await Task.sleep(
          for: policy.delay(beforeRetry: retryNumber, retryAfter: retryAfter)
        )
        continue

      } catch is CancellationError {
        throw CancellationError()

      } catch {
        guard
          attempt < policy.maximumRetries,
          policy.shouldRetry(error)
        else { throw error }
      }

      let retryNumber = attempt + 1
      try await Task.sleep(for: policy.delay(beforeRetry: retryNumber))
    }

    preconditionFailure("Retry loop must return or throw")
  }
}

extension HttpTransport {
  nonisolated func withRetry(
    policy: RetryPolicy = RetryPolicy()
  ) -> RequestRetryTransport {
    RequestRetryTransport(
      transport: self,
      policy: policy)
  }
}
