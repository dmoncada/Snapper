import Foundation
import SwiftData

extension ModelContainer {
  func getSchemaAsJson() throws -> String {
    let models: [[String: Any]] = schema.entities.map { entity in
      let properties: [[String: String]] = entity.properties.map { property in
        [
          "name": property.name,
          "metadataType": String(describing: type(of: property)),
          "metadata": String(describing: property),
        ]
      }

      return [
        "name": entity.name,
        "properties": properties,
      ]
    }

    let json: [String: Any] = [
      "models": models
    ]

    let data = try JSONSerialization.data(
      withJSONObject: json,
      options: [
        .fragmentsAllowed,
        .prettyPrinted,
        .sortedKeys,
      ],
    )

    return String(decoding: data, as: UTF8.self)
  }

  func getModelCountAsJson<T: PersistentModel>(of type: T.Type) throws -> String {
    let context = ModelContext(self)

    let count = try context.fetchCount(FetchDescriptor<T>())

    let json: [String: Any] = [
      "model": String(describing: type),
      "count": count,
    ]

    let data = try JSONSerialization.data(
      withJSONObject: json,
      options: [
        .prettyPrinted,
        .sortedKeys,
      ],
    )

    return String(decoding: data, as: UTF8.self)
  }
}

extension ModelContext {
  func getCount<T: PersistentModel>(for type: T.Type) -> Int {
    (try? self.fetchCount(FetchDescriptor<T>())) ?? -1
  }

  func getCount<T: PersistentModel>(using descriptor: FetchDescriptor<T>) -> Int {
    (try? self.fetchCount(descriptor)) ?? -1
  }

  var sqliteLocation: String? {
    container.configurations.first?.url.path(percentEncoded: false)
  }
}
