import MapKit
import SwiftUI

struct UserLocationMapView: View {
  // MARK: Instance of the location manager
  let locationManager: LocationManager

  // MARK: Properties
  @State var location: CLLocation?

  // MARK: Position of the MapCamera
  @State private var position: MapCameraPosition = .automatic

  // MARK: Body
  var body: some View {
    VStack {
      Map(position: $position) {
        UserAnnotation()
      }
      .clipShape(RoundedRectangle(cornerRadius: 15))
      .shadow(radius: 5)

      Text(location?.description ?? "No location yet")
        .padding()
        .foregroundColor(.secondary)

      Button {
        Task { await self.updateLocation() }
      } label: {
        Text("Get Location")
      }
    }
    .padding()
    .background {
      Color.gray.opacity(0.4)
        .ignoresSafeArea()
    }
    .task {
      // 1. Check if the app is authorized to access the location services of the device
      locationManager.checkAuthorization()
    }
  }

  // MARK: Get the current user location if available
  func updateLocation() async {
    do {
      // 1. Get the current location from the location manager
      location = try await locationManager.currentLocation

      // 2. Update the camera position of the map to center around the user location
      updateMapPosition()

    } catch {
      print("Could not get user location: \(error.localizedDescription)")
    }
  }

  // MARK: Change the camera of the Map view
  func updateMapPosition() {
    if let location = location {
      let regionCenter = CLLocationCoordinate2D(
        latitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude
      )

      let regionSpan = MKCoordinateSpan(
        latitudeDelta: 0.125,
        longitudeDelta: 0.125
      )

      self.position = .region(MKCoordinateRegion(center: regionCenter, span: regionSpan))
    }
  }
}
