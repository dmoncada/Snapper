import SwiftData
import SwiftUI

private struct NoData: PreviewModifier {
  static func makeSharedContext() throws -> ModelContainer {
    try SampleDataStore.makeContainer(limit: 0)
  }

  func body(content: Content, context: ModelContainer) -> some View {
    content
      .modelContainer(context)
  }
}

private struct SampleData: PreviewModifier {
  static func makeSharedContext() throws -> ModelContainer {
    try SampleDataStore.makeContainer()
  }

  func body(content: Content, context: ModelContainer) -> some View {
    content
      .modelContainer(context)
  }
}

extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor static var withoutData: Self = .modifier(NoData())
  @MainActor static var withSampleData: Self = .modifier(SampleData())
}
