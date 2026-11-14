import CoreLocation
import Foundation
import Logging
import MapKit

extension Measurement where UnitType == UnitLength {
  static func meters(_ value: Double) -> Self {
    Self(value: value, unit: .meters)
  }

  static func kilometers(_ value: Double) -> Self {
    Self(value: value, unit: .kilometers)
  }

  static func miles(_ value: Double) -> Self {
    Self(value: value, unit: .miles)
  }
}

struct RecordStoreCandidate: Sendable, Identifiable {
  let id: String
  let name: String
  let latitude: Double
  let longitude: Double
  let phoneNumber: String?
  let website: URL?
  let address: String?

  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(
      latitude: latitude,
      longitude: longitude,
    )
  }

  func distance(from location: CLLocation) -> CLLocationDistance {
    CLLocation(
      latitude: latitude,
      longitude: longitude,
    )
    .distance(from: location)
  }
}

struct MapKitRecordStoreLocator: RecordStoreLocating {
  private static let searchQueries = [
    "record stores",
    "vinyl record shops",
    "used music and record stores",
  ]

  init(logger: Logger = .current) {
    self.logger = logger
  }

  private let logger: Logger

  func locate(
    near location: CLLocation,
    within radius: Measurement<UnitLength>,
    limit: Int,
  ) async throws -> [RecordStoreCandidate] {
    try Task.checkCancellation()

    guard limit > 0 else { return [] }

    let radiusInMeters = radius.converted(to: .meters).value

    guard
      radiusInMeters.isFinite,
      radiusInMeters > 0
    else { return [] }

    let region = MKCoordinateRegion(
      center: location.coordinate,
      latitudinalMeters: radiusInMeters * 2,
      longitudinalMeters: radiusInMeters * 2,
    )

    logger.debug(
      "Searching for nearby record stores.",
      metadata: [
        "radius_meters": "\(radiusInMeters)",
        "limit": "\(limit)",
        "query_count": "\(Self.searchQueries.count)",
      ],
    )

    // Execute all searches concurrently.
    let results = try await withThrowingTaskGroup(
      of: [RecordStoreCandidate].self,
      returning: [[RecordStoreCandidate]].self,
    ) { group in
      for query in Self.searchQueries {
        group.addTask {
          try Task.checkCancellation()

          do {
            let candidates = try await Self.search(
              query: query,
              region: region,
              center: location,
              radius: radiusInMeters,
            )

            logger.debug(
              "Record store search completed.",
              metadata: [
                "query": "\(query)",
                "result_count": "\(candidates.count)",
              ],
            )

            return candidates
          } catch is CancellationError {
            throw CancellationError()
          } catch {
            // Preserve partial results for ordinary search failures.
            try Task.checkCancellation()

            logger.error(
              "Record store search failed.",
              metadata: [
                "query": "\(query)",
                "error": "\(error)",
              ],
            )

            return []
          }
        }
      }

      var results: [[RecordStoreCandidate]] = []

      for try await result in group {
        results.append(result)
      }

      return results
    }

    try Task.checkCancellation()

    // Merge and deduplicate.
    var seen = Set<String>()
    var unique: [RecordStoreCandidate] = []

    for candidate in results.flatMap({ $0 }) {
      if seen.insert(candidate.id).inserted {
        unique.append(candidate)
      }
    }

    // Closest first.
    let nearby =
      unique
      .sorted {
        $0.distance(from: location) < $1.distance(from: location)
      }
      .prefix(limit)
      .map { $0 }

    logger.info(
      "Nearby record store search completed.",
      metadata: [
        "total_results": "\(results.flatMap { $0 }.count)",
        "unique_results": "\(unique.count)",
        "returned_results": "\(nearby.count)",
      ],
    )

    return nearby
  }

  private static func search(
    query: String,
    region: MKCoordinateRegion,
    center: CLLocation,
    radius: CLLocationDistance,
  ) async throws -> [RecordStoreCandidate] {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    request.resultTypes = .pointOfInterest
    request.region = region

    let response = try await MKLocalSearch(request: request).start()
    try Task.checkCancellation()

    return response.mapItems.compactMap { item in
      let distance = center.distance(from: item.location)

      guard distance <= radius else { return nil }

      let id =
        item.identifier?.rawValue
        ?? fallbackId(name: item.name, location: item.location)

      return RecordStoreCandidate(
        id: id,
        name: item.name ?? "Unknown store",
        latitude: item.location.coordinate.latitude,
        longitude: item.location.coordinate.longitude,
        phoneNumber: item.phoneNumber,
        website: item.url,
        address: item.address?.fullAddress,
      )
    }
  }

  private static func fallbackId(
    name: String?,
    location: CLLocation,
  ) -> String {
    let normalizedName = (name ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()

    return [
      normalizedName,
      String(format: "%.5f", location.coordinate.latitude),
      String(format: "%.5f", location.coordinate.longitude),
    ]
    .joined(separator: "|")
  }
}

extension RecordStoreLocating where Self == MapKitRecordStoreLocator {
  static var live: Self { Self() }
}
