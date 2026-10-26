import SwiftData

@MainActor
enum SampleDataStore {
  static func makeContainer(limit: Int? = nil) throws -> ModelContainer {
    let configuration = ModelConfiguration(
      isStoredInMemoryOnly: true
    )

    let container = try ModelContainer(
      for: SnapperStore.schema,
      configurations: [configuration],
    )

    if let limit, limit == 0 {
      return container
    }

    let file = try SampleDataLoader.importData()

    try SampleDataLoader.insert(
      file,
      into: container.mainContext,
      limit: limit,
    )

    return container
  }
}
