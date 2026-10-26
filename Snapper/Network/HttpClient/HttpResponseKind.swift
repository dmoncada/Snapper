nonisolated enum HttpResponseKind<Response: Sendable>: Sendable {
  case json
  case empty(Response)
}
