import CoreLocation
import Foundation
import MapKit

struct AlbumLocation: Sendable {
  let latitude: Double
  let longitude: Double
  let horizontalAccuracy: Double
  let capturedAt: Date
  let placeLabel: String?
}

@MainActor
final class AlbumLocationCaptureService {
  func captureCurrentLocation() async -> AlbumLocation? {
    let session = CLServiceSession(authorization: .whenInUse)
    _ = session

    let location = await withTaskGroup(of: AlbumLocation?.self) { group in
      group.addTask {
        do {
          for try await update in CLLocationUpdate.liveUpdates() {
            if update.authorizationDenied || update.authorizationDeniedGlobally {
              return nil
            }

            guard let location = update.location,
              location.horizontalAccuracy >= 0,
              abs(location.timestamp.timeIntervalSinceNow) < 120
            else {
              continue
            }

            return AlbumLocation(
              latitude: location.coordinate.latitude,
              longitude: location.coordinate.longitude,
              horizontalAccuracy: location.horizontalAccuracy,
              capturedAt: location.timestamp,
              placeLabel: nil)
          }
        } catch {
          return nil
        }

        return nil
      }

      group.addTask {
        try? await Task.sleep(for: .seconds(15))
        return nil
      }

      let result = await group.next() ?? nil
      group.cancelAll()
      return result
    }

    guard let location else { return nil }
    let label = await placeLabel(for: location)
    return AlbumLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      horizontalAccuracy: location.horizontalAccuracy,
      capturedAt: location.capturedAt,
      placeLabel: label)
  }

  private func placeLabel(for location: AlbumLocation) async -> String? {
    let coordinate = CLLocation(latitude: location.latitude, longitude: location.longitude)
    guard let request = MKReverseGeocodingRequest(location: coordinate) else { return nil }

    do {
      return try await request.mapItems.first?.address?.shortAddress
    } catch {
      return nil
    }
  }
}
