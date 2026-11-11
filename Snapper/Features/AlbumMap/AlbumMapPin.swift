import MapKit

struct AlbumMapPin: Identifiable {
  let id: UUID
  let albums: [Album]
  let coordinate: CLLocationCoordinate2D

  var isCluster: Bool { albums.count > 1 }
}
