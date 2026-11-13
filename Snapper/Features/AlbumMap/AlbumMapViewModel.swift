import MapKit
import Observation

@MainActor
@Observable
final class AlbumMapViewModel {
  private(set) var pins: [AlbumMapPin] = []

  // Group annotations that would overlap at the current map scale.
  func updatePins(
    for albums: [Album],
    pointForCoordinate: (CLLocationCoordinate2D) -> CGPoint?,
  ) {
    let visible = albums.compactMap { album -> (Album, CLLocationCoordinate2D, CGPoint)? in
      guard
        let coordinate = album.mapCoordinate,
        let point = pointForCoordinate(coordinate)
      else { return nil }

      return (album, coordinate, point)
    }

    var groups: [[Int]] = []
    let minimumSeparation: CGFloat = 96

    for index in visible.indices {
      let point = visible[index].2

      if let groupIndex = groups.firstIndex(where: { group in
        group.contains { member in
          let other = visible[member].2
          return hypot(point.x - other.x, point.y - other.y) < minimumSeparation
        }
      }) {
        groups[groupIndex].append(index)
      } else {
        groups.append([index])
      }
    }

    pins = groups.map { indices in
      let members = indices.map { visible[$0] }
      let albums = members.map(\.0)
      let latitude = members.map(\.1.latitude).reduce(0, +) / Double(members.count)
      let longitude = members.map(\.1.longitude).reduce(0, +) / Double(members.count)

      return AlbumMapPin(
        id: albums[0].id,
        albums: albums,
        coordinate: CLLocationCoordinate2D(
          latitude: latitude,
          longitude: longitude,
        ),
      )
    }
  }
}
