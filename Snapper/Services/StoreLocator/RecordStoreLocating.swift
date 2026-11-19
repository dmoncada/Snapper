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

struct FailRecordStoreLocator: RecordStoreLocating {
  let delay: Duration

  func locate(
    near location: CLLocation,
    within radius: Measurement<UnitLength>,
    limit: Int,
  ) async throws -> [RecordStoreCandidate] {
    try? await Task.sleep(for: delay)
    throw URLError(.badURL)
  }
}

extension RecordStoreLocating where Self == NullRecordStoreLocator {
  static var null: Self { Self() }
}

extension RecordStoreLocating where Self == FailRecordStoreLocator {
  static var fail: Self {
    Self(delay: .seconds(1))
  }
  static func fail(delay: Duration) -> Self {
    Self(delay: delay)
  }
}
