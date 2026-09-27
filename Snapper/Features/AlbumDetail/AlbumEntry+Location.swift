import MapKit
import SwiftUI

extension AlbumEntry {
  var location: CLLocation? {
    guard let latitude, let longitude else {
      return nil
    }

    return CLLocation(
      latitude: latitude,
      longitude: longitude
    )
  }

  var position: MapCameraPosition? {
    guard let location else {
      return nil
    }

    return .region(
      MKCoordinateRegion(
        center: location.coordinate,
        span: MKCoordinateSpan(
          latitudeDelta: 0.125,
          longitudeDelta: 0.125
        )
      )
    )
  }
}
