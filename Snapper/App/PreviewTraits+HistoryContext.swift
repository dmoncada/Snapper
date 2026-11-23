#if DEBUG
import Logging
import SwiftData
import SwiftUI

enum HistoryContextKind {
  case empty
  case `default`
  case resetDates(to: Date = .now)
}

struct HistoryContextModifier: PreviewModifier {
  static func makeSharedContext() throws {}

  let kind: HistoryContextKind

  func body(content: Content, context: Void) -> some View {
    HistoryPreview(content: content, kind: kind)
  }
}

private struct HistoryPreview: View {
  let content: PreviewModifierContent
  let container: ModelContainer

  @State private var detailViewModel: AlbumDetailViewModel
  @State private var historyViewModel: AlbumHistoryViewModel

  init(
    content: PreviewModifierContent,
    kind: HistoryContextKind,
  ) {
    let container: ModelContainer

    do {
      switch kind {
      case .empty:
        container = try SampleDataStore.makeEmpty()
      case .default:
        container = try SampleDataStore.makeContainer()
      case .resetDates(let date):
        container = try SampleDataStore.makeContainer()
        try Self.resetDates(to: date, in: container.mainContext)
      }
    } catch {
      fatalError("Unable to create schema.")
    }

    self.content = content
    self.container = container

    let client: ApiClient = .stub(container)
    let logger1 = PreviewLoggerFactory.makeLogger("detail")
    let logger2 = PreviewLoggerFactory.makeLogger("history")

    _detailViewModel = State(
      initialValue: .init(logger: logger1, apiClient: client)
    )
    _historyViewModel = State(
      initialValue: .init(logger: logger2, context: container.mainContext)
    )
  }

  var body: some View {
    content
      .modelContainer(container)
      .environment(detailViewModel)
      .environment(historyViewModel)
      .environment(\.navigation, .init())
      .environment(\.previewPlayer, .live)
  }

  private static func resetDates(to date: Date, in context: ModelContext) throws {
    for album in try context.fetch(FetchDescriptor<Album>()) {
      album.selectedAt = date
    }

    try context.save()
  }
}

extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor static var withHistoryContext: Self =
    .modifier(HistoryContextModifier(kind: .default))

  @MainActor static func withHistoryContext(kind: HistoryContextKind) -> Self {
    .modifier(HistoryContextModifier(kind: kind))
  }
}
#endif
