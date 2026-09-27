import CoreLocation
import Foundation

@MainActor
@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
  enum LocationManagerError: String, Error {
    case replacedContinuation = "Continuation replaced."
    case locationNotFound = "No location found."
  }

  private let manager = CLLocationManager()
  private var continuation: CheckedContinuation<CLLocation, Error>?

  override init() {
    super.init()
    manager.delegate = self
  }

  var currentLocation: CLLocation {
    get async throws {
      if self.continuation != nil {
        self.continuation?.resume(throwing: LocationManagerError.replacedContinuation)
        self.continuation = nil
      }

      return try await withCheckedThrowingContinuation { continuation in
        self.continuation = continuation
        manager.requestLocation()
      }
    }
  }

  func checkAuthorization() {
    switch manager.authorizationStatus {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    default:
      return
    }
  }

  // MARK: CLLocationManagerDelegate implementation.

  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    if let lastLocation = locations.last {
      continuation?.resume(returning: lastLocation)
      continuation = nil

    } else {
      continuation?.resume(throwing: LocationManagerError.locationNotFound)
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: Error
  ) {
    continuation?.resume(throwing: error)
    continuation = nil
  }
}
