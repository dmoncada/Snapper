import Foundation
import FoundationModels

nonisolated struct AnthropicToolCall: Sendable {
  let id: String
  let name: String
  let input: String
}

nonisolated struct AnthropicMessageResponse: Sendable {
  let text: String
  let toolCalls: [AnthropicToolCall]
  let inputTokens: Int
  let outputTokens: Int
}

nonisolated enum AnthropicClientError: Error, LocalizedError, Sendable {
  case missingApiKey
  case invalidRequest
  case invalidResponse
  case httpStatus(Int, String)

  var errorDescription: String? {
    switch self {
    case .missingApiKey:
      "Set ANTHROPIC_API_KEY in the app configuration."
    case .invalidRequest:
      "Snapper couldn’t prepare the Anthropic request."
    case .invalidResponse:
      "Anthropic returned an unexpected response."
    case .httpStatus(let code, let message):
      "Anthropic request failed (HTTP \(code)): \(message)"
    }
  }
}

nonisolated struct AnthropicMessagesClient: Sendable {
  private let apiKey: String
  private let modelID: String
  private let transport: any HttpTransport

  init(
    apiKey: String,
    modelID: String,
    transport: any HttpTransport = UrlSessionTransport()
  ) {
    self.apiKey = apiKey
    self.modelID = modelID
    self.transport = transport
  }

  func respond(to request: LanguageModelExecutorGenerationRequest) async throws
    -> AnthropicMessageResponse
  {
    try Task.checkCancellation()

    let payload = try makePayload(for: request)
    guard
      JSONSerialization.isValidJSONObject(payload),
      let body = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
    else {
      throw AnthropicClientError.invalidRequest
    }

    guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
      throw AnthropicClientError.invalidRequest
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = body
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

    let result = try await transport.send(urlRequest)
    guard (200 ..< 300).contains(result.response.statusCode) else {
      let message = Self.errorMessage(from: result.data)
      throw AnthropicClientError.httpStatus(result.response.statusCode, message)
    }

    guard
      let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
      let content = json["content"] as? [[String: Any]]
    else {
      throw AnthropicClientError.invalidResponse
    }

    let text = content.compactMap { block -> String? in
      guard block["type"] as? String == "text" else { return nil }
      return block["text"] as? String
    }.joined()

    let toolCalls = content.compactMap { block -> AnthropicToolCall? in
      guard
        block["type"] as? String == "tool_use",
        let id = block["id"] as? String,
        let name = block["name"] as? String,
        let input = block["input"],
        let inputData = try? JSONSerialization.data(withJSONObject: input, options: [.sortedKeys]),
        let inputString = String(data: inputData, encoding: .utf8)
      else {
        return nil
      }

      return AnthropicToolCall(id: id, name: name, input: inputString)
    }

    let usage = json["usage"] as? [String: Any]
    return AnthropicMessageResponse(
      text: text,
      toolCalls: toolCalls,
      inputTokens: usage?["input_tokens"] as? Int ?? 0,
      outputTokens: usage?["output_tokens"] as? Int ?? 0
    )
  }

  private func makePayload(for request: LanguageModelExecutorGenerationRequest) throws
    -> [String: Any]
  {
    var systemText = ""
    var messages: [[String: Any]] = []

    for entry in request.transcript {
      switch entry {
      case .instructions(let instructions):
        systemText += instructions.segments.compactMap(Self.text(from:)).joined(separator: "\n")

      case .prompt(let prompt):
        let text = prompt.segments.compactMap(Self.text(from:)).joined(separator: "\n")
        // if text.isEmpty == false {
        if text.count > 0 {
          messages.append([
            "role": "user",
            "content": text,
          ])
        }

      case .response(let response):
        let text = response.segments.compactMap(Self.text(from:)).joined(separator: "\n")
        // if text.isEmpty == false {
        if text.count > 0 {
          messages.append([
            "role": "assistant",
            "content": text,
          ])
        }

      case .toolCalls(let calls):
        let content: [[String: Any]] = calls.map { call in
          [
            "type": "tool_use",
            "id": call.id,
            "name": call.toolName,
            "input": Self.jsonObject(from: call.arguments.jsonString) ?? [:],
          ]
        }
        messages.append(["role": "assistant", "content": content])

      case .toolOutput(let output):
        let text = output.segments.compactMap(Self.text(from:)).joined(separator: "\n")
        messages.append([
          "role": "user",
          "content": [
            [
              "type": "tool_result",
              "tool_use_id": output.id,
              "content": text,
            ]
          ],
        ])

      case .reasoning:
        // Haiku uses no extended thinking, so reasoning history is omitted.
        continue

      @unknown default:
        continue
      }
    }

    if messages.isEmpty {
      messages.append(["role": "user", "content": ""])
    }

    var payload: [String: Any] = [
      "model": modelID,
      "max_tokens": min(max(request.generationOptions.maximumResponseTokens ?? 256, 1), 1_024),
      "messages": messages,
    ]

    // if systemText.isEmpty == false {
    if systemText.count > 0 {
      payload["system"] = systemText
    }

    let definitions = request.enabledToolDefinitions
    // if definitions.isEmpty == false {
    if definitions.count > 0 {
      payload["tools"] = try definitions.map { definition -> [String: Any] in
        guard let schema = Self.jsonObject(from: definition.parameters) else {
          throw AnthropicClientError.invalidRequest
        }

        return [
          "name": definition.name,
          "description": definition.description,
          "input_schema": schema,
        ]
      }
    }

    if let schema = request.schema {
      guard let jsonSchema = Self.jsonObject(from: schema) else {
        throw AnthropicClientError.invalidRequest
      }
      payload["output_config"] = [
        "format": [
          "type": "json_schema",
          "schema": jsonSchema,
        ]
      ]
    }

    return payload
  }

  private static func text(from segment: Transcript.Segment) -> String? {
    switch segment {
    case .text(let textSegment):
      textSegment.content
    case .structure(let structuredSegment):
      structuredSegment.content.jsonString
    case .attachment:
      nil
    @unknown default:
      nil
    }
  }

  private static func jsonObject(from json: String) -> Any? {
    guard let data = json.data(using: .utf8) else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  }

  private static func jsonObject(from schema: GenerationSchema) -> [String: Any]? {
    guard
      let data = try? JSONEncoder().encode(schema),
      let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return nil
    }
    return compatibleSchemaValue(value) as? [String: Any]
  }

  private static func compatibleSchemaValue(_ value: Any) -> Any {
    if var object = value as? [String: Any] {
      object.removeValue(forKey: "x-order")
      return object.mapValues(compatibleSchemaValue)
    }

    if let array = value as? [Any] {
      return array.map(compatibleSchemaValue)
    }

    return value
  }

  private static func errorMessage(from data: Data) -> String {
    guard
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let error = json["error"] as? [String: Any],
      let message = error["message"] as? String
    else {
      return "The service didn’t accept the request."
    }
    return message
  }
}
