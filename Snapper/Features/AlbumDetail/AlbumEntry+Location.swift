import MapKit
import SwiftUI

extension AlbumEntry {
  var location: CLLocation? {
    guard let latitude, let longitude else {
      return nil
    }

    return CLLocation(
      latitude: latitude,
      longitude: longitude,
    )
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
