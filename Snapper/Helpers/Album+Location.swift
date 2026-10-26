import MapKit
import SwiftUI

extension Album {
  var location: CLLocation? {
    if let latitude, let longitude {
      return CLLocation(
        latitude: latitude,
        longitude: longitude,
      )
    }

    return nil
  }

  var locationStatus: AlbumLocationStatus {
    if let raw = locationStatusRaw, let status = AlbumLocationStatus(rawValue: raw) {
      return status
    }

    return location == nil
      ? .unavailable
      : .captured
  }
}

extension CLLocation {
  var position: MapCameraPosition {
    .region(
      MKCoordinateRegion(
        center: coordinate,
        span: MKCoordinateSpan(
          latitudeDelta: 0.125,
          longitudeDelta: 0.125,
        ),
      )
    )
  }
}
