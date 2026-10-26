import CoreLocation
import SwiftUI

enum LocationAuthorization: Sendable {
  case unknown
  case authorized
  case denied
  case restricted
  case servicesDisabled
}

enum LocationError: Error, Sendable {
  case servicesDisabled
  case permissionDenied
  case permissionRestricted
  case unavailable
  case requestInProgress
}

@MainActor
protocol LocationProviding: AnyObject {
  var authorization: LocationAuthorization { get }

  @discardableResult
  func requestAuthorization() async -> LocationAuthorization

  func getLocation() async throws -> CLLocation
}

@MainActor
final class NullLocationProvider: LocationProviding {
  var authorization: LocationAuthorization { .unknown }

  func requestAuthorization() async -> LocationAuthorization {
    .unknown
  }

  func getLocation() async throws -> CLLocation {
    throw LocationError.unavailable
  }
}

enum LocationStub {
  case sanFrancisco
  case newYork

  var location: CLLocation {
    let coordinate: CLLocationCoordinate2D

    switch self {
    case .sanFrancisco:
      coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    case .newYork:
      coordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    }

    return CLLocation(
      latitude: coordinate.latitude,
      longitude: coordinate.longitude,
    )
  }
}

@MainActor
final class StubLocationProvider: LocationProviding {
  let authorization: LocationAuthorization = .authorized

  private let location: CLLocation

  init(location: CLLocation) {
    self.location = location
  }

  func requestAuthorization() async -> LocationAuthorization {
    .authorized
  }

  func getLocation() async throws -> CLLocation {
    location
  }
}

extension LocationProviding where Self == LocationProvider {
  static var live: Self { Self() }
}

extension LocationProviding where Self == NullLocationProvider {
  static var null: Self { Self() }
}

extension LocationProviding where Self == StubLocationProvider {
  static func stub(_ stub: LocationStub) -> Self {
    Self(location: stub.location)
  }

  static func stub(location: CLLocation) -> Self {
    Self(location: location)
  }
}
