import CoreLocation
import Observation

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

// @MainActor
// @Observable
final class LocationService: NSObject {
  private(set) var authorization: LocationAuthorization = .unknown

  private var authorizationContinuation: CheckedContinuation<LocationAuthorization, Never>?
  private var locationContinuation: CheckedContinuation<CLLocation, Error>?
  private let locationManager = CLLocationManager()

  override init() {
    super.init()

    locationManager.delegate = self
    updateAuthorization()
  }

  @discardableResult
  func requestPermission() async -> LocationAuthorization {
    updateAuthorization()

    guard authorization == .unknown else {
      return authorization
    }

    return await withTaskCancellationHandler {
      await withCheckedContinuation { continuation in
        // Avoid replacing an existing continuation.
        guard authorizationContinuation == nil else { return }

        authorizationContinuation = continuation
        locationManager.requestWhenInUseAuthorization()
      }
    } onCancel: {
      Task { @MainActor [weak self] in
        self?.resumeAuthorization(with: .unknown)
      }
    }
  }

  func getLocation() async throws -> CLLocation {
    try Task.checkCancellation()

    let authorization = await resolvedAuthorization()
    try Task.checkCancellation()

    switch authorization {
    case .authorized: break
    case .denied: throw LocationError.permissionDenied
    case .restricted: throw LocationError.permissionRestricted
    case .servicesDisabled: throw LocationError.servicesDisabled
    case .unknown: throw LocationError.unavailable
    }

    return try await requestLocation()
  }

  private func resolvedAuthorization() async -> LocationAuthorization {
    updateAuthorization()

    if authorization == .unknown {
      return await requestPermission()
    }

    return authorization
  }

  private func requestLocation() async throws -> CLLocation {
    guard locationContinuation == nil else { throw LocationError.requestInProgress }

    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        locationContinuation = continuation
        locationManager.requestLocation()
      }
    } onCancel: {
      Task { @MainActor [weak self] in
        self?.cancelLocationRequest()
      }
    }
  }

  private func cancelLocationRequest() {
    guard let continuation = locationContinuation else { return }

    locationContinuation = nil
    continuation.resume(throwing: CancellationError())
  }

  private func updateAuthorization() {
    switch locationManager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse: authorization = .authorized
    case .denied: authorization = .denied
    case .restricted: authorization = .restricted
    case .notDetermined: authorization = .unknown
    @unknown default: authorization = .unknown
    }
  }

  private func resumeAuthorization(with result: LocationAuthorization) {
    guard let continuation = authorizationContinuation else { return }

    authorizationContinuation = nil
    continuation.resume(returning: result)
  }

  private func resumeLocation(with result: Result<CLLocation, Error>) {
    guard let continuation = locationContinuation else { return }

    locationContinuation = nil

    switch result {
    case .success(let location): continuation.resume(returning: location)
    case .failure(let error): continuation.resume(throwing: error)
    }
  }
}

extension LocationService: CLLocationManagerDelegate {
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    updateAuthorization()
    if authorization == .unknown { return }
    resumeAuthorization(with: authorization)
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else {
      resumeLocation(with: .failure(LocationError.unavailable))
      return
    }

    resumeLocation(with: .success(location))
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    guard let error = error as? CLError else {
      resumeLocation(with: .failure(error))
      return
    }

    switch error.code {
    case .denied:
      updateAuthorization()

      switch authorization {
      case .servicesDisabled: resumeLocation(with: .failure(LocationError.servicesDisabled))
      case .restricted: resumeLocation(with: .failure(LocationError.permissionRestricted))
      default: resumeLocation(with: .failure(LocationError.permissionDenied))
      }

    case .locationUnknown: resumeLocation(with: .failure(LocationError.unavailable))
    default: resumeLocation(with: .failure(error))
    }
  }
}
