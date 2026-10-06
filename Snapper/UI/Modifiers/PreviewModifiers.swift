import SwiftData
import SwiftUI

struct NoData: PreviewModifier {
  static func makeSharedContext() throws -> ModelContainer {
    let container = try ModelContainer(
      for: AlbumEntry.self,
      configurations: .init(isStoredInMemoryOnly: true),
    )
    return container
  }

  func body(content: Content, context: ModelContainer) -> some View {
    content
      .modelContainer(context)
  }
}

struct SampleData: PreviewModifier {
  static func makeSharedContext() throws -> ModelContainer {
    try SampleAlbumStore.makeContainer()
  }

  func body(content: Content, context: ModelContainer) -> some View {
    content
      .modelContainer(context)
  }
}

extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor static var withoutData: Self = .modifier(NoData())
}
extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor static var withSampleData: Self = .modifier(SampleData())
}
