import CoreLocation
import Foundation

@MainActor
protocol RecordStoreLocating {
  func locate(
    near location: CLLocation,
    within radius: Measurement<UnitLength>,
    limit: Int,
  ) async throws -> [RecordStoreCandidate]
}

struct NullRecordStoreLocator: RecordStoreLocating {
  func locate(
    near location: CLLocation,
    within radius: Measurement<UnitLength>,
    limit: Int,
  ) async throws -> [RecordStoreCandidate] {
    []
  }
}

extension RecordStoreLocating where Self == NullRecordStoreLocator {
  static var null: Self { Self() }
}
