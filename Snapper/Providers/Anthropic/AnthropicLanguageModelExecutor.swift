import Foundation
import FoundationModels

nonisolated struct AnthropicLanguageModelExecutor: LanguageModelExecutor {
  typealias Model = AnthropicLanguageModel

  let client: AnthropicMessagesClient

  init(configuration: AnthropicLanguageModel.Configuration) throws {
    guard
      let apiKey = configuration.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines),
      apiKey.count > 0
    else {
      throw AnthropicClientError.missingApiKey
    }

    client = AnthropicMessagesClient(
      apiKey: apiKey,
      modelID: configuration.modelID,
      transport: UrlSessionTransport()
    )
  }

  func respond(
    to request: LanguageModelExecutorGenerationRequest,
    model: AnthropicLanguageModel,
    streamingInto channel: LanguageModelExecutorGenerationChannel
  ) async throws {
    try Task.checkCancellation()
    let response = try await client.respond(to: request)

    // if response.text.isEmpty == false {
    if response.text.count > 0 {
      await channel.send(
        .response(
          entryID: nil,
          action: .appendText(response.text, tokenCount: response.outputTokens)
        )
      )
    }

    // guard response.toolCalls.isEmpty == false else { return }
    if response.toolCalls.isEmpty { return }
    let callsEntryID = UUID().uuidString

    for toolCall in response.toolCalls {
      await channel.send(
        .toolCalls(
          entryID: callsEntryID,
          action: .toolCall(
            id: toolCall.id,
            name: toolCall.name,
            action: .appendArguments(toolCall.input, tokenCount: 0)
          )
        )
      )
    }

    await channel.send(
      .response(
        entryID: nil,
        action: .updateUsage(
          input: .init(totalTokenCount: response.inputTokens, cachedTokenCount: 0),
          output: .init(totalTokenCount: response.outputTokens, reasoningTokenCount: 0)
        )
      )
    )
  }
}
