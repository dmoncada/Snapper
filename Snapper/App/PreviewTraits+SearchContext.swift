import SwiftData
import SwiftUI

enum SearchContextKind {
  case live
  case slow
  case fail
  case stub(Int = 10)
}

struct SearchContextModifier: PreviewModifier {
  static func makeSharedContext() throws -> ModelContainer {
    try SampleDataStore.makeContainer()
  }

  let kind: SearchContextKind
  let load: Bool

  init(kind: SearchContextKind, load: Bool = true) {
    self.kind = kind
    self.load = load
  }

  private func makeClient(_ container: ModelContainer) -> (ApiClient, Int) {
    switch kind {
    case .live: (.live, 10)
    case .fail: (.fail, 10)
    case .slow: (.slow, 10)
    case .stub(let count): (.stub(container), count)
    }
  }

  func body(content: Content, context: ModelContainer) -> some View {
    let (client, count) = makeClient(context)

    SearchPreview(
      content: content,
      context: context,
      apiClient: client,
      count: count,
      load: load,
    )
  }
}

private struct SearchPreview: View {
  let content: PreviewModifierContent
  let context: ModelContainer
  let count: Int
  let load: Bool

  @State private var searchViewModel: AlbumSearchViewModel
  @State private var detailViewModel: AlbumDetailViewModel
  @State private var locationCoordinator: AlbumLocationCaptureCoordinator

  init(
    content: PreviewModifierContent,
    context: ModelContainer,
    apiClient: ApiClient,
    count: Int = 10,
    load: Bool = true,
  ) {
    self.content = content
    self.context = context
    self.count = count
    self.load = load

    _searchViewModel = State(
      initialValue: AlbumSearchViewModel(
        apiClient: apiClient
      )
    )

    _detailViewModel = State(
      initialValue: AlbumDetailViewModel(
        apiClient: apiClient
      )
    )

    _locationCoordinator = State(
      initialValue: AlbumLocationCaptureCoordinator(
        locator: .stub(.newYork)
      )
    )
  }

  var body: some View {
    content
      .modelContainer(context)
      .environment(searchViewModel)
      .environment(detailViewModel)
      .environment(locationCoordinator)
      .environment(\.previewPlayer, .live)
      .task {
        guard load else { return }
        await searchViewModel.search(
          by: .term("stub"),
          debounce: .zero,
          limit: count,
        )
      }
  }
}

extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor static var withSearchContext: Self =
    .modifier(SearchContextModifier(kind: .live, load: false))

  @MainActor static func withSearchContext(kind: SearchContextKind, load: Bool = true) -> Self {
    .modifier(SearchContextModifier(kind: kind, load: load))
  }
}
