import SwiftData

enum SnapperStore {
  static var schema: Schema { Schema(SnapperSchema.models) }

  static func makeContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(
      schema: schema,
      groupContainer: .identifier(Constants.appGroup),
    )

    return try ModelContainer(
      for: schema,
      configurations: [configuration],
    )
  }
}
