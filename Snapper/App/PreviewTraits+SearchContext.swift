#if DEBUG
import Logging
import SwiftData
import SwiftUI

enum SearchContextKind {
  case slow
  case fail
  case stub(count: Int = 10)
}

struct SearchContextModifier: PreviewModifier {
  static func makeSharedContext() throws -> ModelContainer {
    try SampleDataStore.makeContainer()
  }

  let kind: SearchContextKind

  private func makeClient(_ container: ModelContainer) -> ApiClient {
    switch kind {
    case .fail: .fail
    case .slow: .slow
    case .stub(let count): .stub(container, count: count)
    }
  }

  func body(content: Content, context: ModelContainer) -> some View {
    let client = makeClient(context)

    SearchPreview(
      content: content,
      context: context,
      apiClient: client,
    )
  }
}

private struct SearchPreview: View {
  let content: PreviewModifierContent
  let context: ModelContainer

  @State private var searchViewModel: AlbumSearchViewModel
  @State private var detailViewModel: AlbumDetailViewModel
  @State private var locationCoordinator: AlbumLocationCaptureCoordinator

  init(
    content: PreviewModifierContent,
    context: ModelContainer,
    apiClient: ApiClient,
  ) {
    self.content = content
    self.context = context

    let logger1 = PreviewLoggerFactory.makeLogger("search")
    let logger2 = PreviewLoggerFactory.makeLogger("detail")

    _searchViewModel = State(
      initialValue: .init(logger: logger1, apiClient: apiClient, defaultDuration: .zero)
    )
    _detailViewModel = State(
      initialValue: .init(logger: logger2, apiClient: apiClient)
    )
    _locationCoordinator = State(
      initialValue: .init(locator: .stub(.newYork))
    )
  }

  var body: some View {
    content
      .modelContainer(context)
      .environment(searchViewModel)
      .environment(detailViewModel)
      .environment(locationCoordinator)
      .environment(\.previewPlayer, .live)
  }
}

extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor static var withSearchContext: Self =
    .modifier(SearchContextModifier(kind: .stub(count: 10)))

  @MainActor static func withSearchContext(kind: SearchContextKind) -> Self {
    .modifier(SearchContextModifier(kind: kind))
  }
}
#endif
