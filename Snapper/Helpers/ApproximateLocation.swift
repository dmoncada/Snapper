import CoreLocation
import Foundation
import MapKit

struct ApproximateLocation {
  static func getName(
    _ location: CLLocation
  ) async throws -> String? {
    guard let request = MKReverseGeocodingRequest(location: location) else {
      return nil
    }

    let items = try await request.mapItems

    guard let item = items.first else {
      return nil
    }

    if let place = item.addressRepresentations?.cityWithContext(.short) {
      return place
    }

    if let place = item.address?.shortAddress {
      return place
    }

    return nil
  }
}
