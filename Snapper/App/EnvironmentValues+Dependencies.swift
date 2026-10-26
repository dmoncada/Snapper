import SwiftUI

extension EnvironmentValues {
  @Entry var apiClient: any ApiClient = .null
  @Entry var previewPlayer: any PreviewPlaying = .null
  @Entry var imageRecognizer: any ImageRecognizing = .null
  @Entry var locationProvider: any LocationProviding = .null
}
