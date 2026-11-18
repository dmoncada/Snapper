import CoreLocation
import Foundation
import MapKit

struct ApproximateLocation {
  static func format(
    _ location: CLLocation
  ) async throws -> LocalizedStringResource? {
    guard let request = MKReverseGeocodingRequest(location: location) else {
      return nil
    }

    let items = try await request.mapItems

    guard let item = items.first else {
      return nil
    }

    if let place = item.addressRepresentations?.cityWithContext(.short) {
      return "Near \(place)"
    }

    if let place = item.address?.shortAddress {
      return "Near \(place)"
    }

    return nil
  }
}
