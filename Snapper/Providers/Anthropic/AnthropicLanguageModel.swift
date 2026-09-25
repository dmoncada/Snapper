import Foundation
import FoundationModels

nonisolated struct AnthropicLanguageModel: LanguageModel {
  typealias Executor = AnthropicLanguageModelExecutor

  static let defaultModelId = "claude-haiku-4-5-20251001"

  struct Configuration: Hashable, Sendable {
    let apiKey: String?
    let modelID: String

    init(apiKey: String?, modelID: String) {
      self.apiKey = apiKey
      self.modelID = modelID
    }
  }

  private let configuration: Configuration

  init(
    apiKey: String? = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String,
    modelID: String = Self.defaultModelId
  ) {
    configuration = Configuration(apiKey: apiKey, modelID: modelID)
  }

  var capabilities: LanguageModelCapabilities {
    LanguageModelCapabilities([.toolCalling, .guidedGeneration])
  }

  var executorConfiguration: Configuration {
    configuration
  }
}
