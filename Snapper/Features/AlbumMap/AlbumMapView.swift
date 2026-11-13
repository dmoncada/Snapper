import MapKit
import SwiftData
import SwiftUI

struct AlbumMapView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context

  @Query(sort: \Album.selectedAt, order: .reverse) private var albums: [Album]

  @State private var model = AlbumMapViewModel()
  @State private var position: MapCameraPosition = .automatic

  @State private var selectedAlbum: Album?
  @State private var selectedCluster: AlbumMapPin?

  var body: some View {
    NavigationStack {
      MapReader { proxy in
        Map(position: $position) {
          ForEach(model.pins) { pin in
            Annotation(
              pin.isCluster ? "Albums" : pin.albums[0].title,
              coordinate: pin.coordinate,
              anchor: .bottom,
            ) {
              if pin.isCluster {
                AlbumClusterPin(count: pin.albums.count) {
                  selectedCluster = pin
                }
              } else if let album = pin.albums.first {
                AlbumSinglePin(title: album.title, artist: album.artist) {
                  selectedAlbum = album
                }
              }
            }
            .annotationTitles(.hidden)
          }
        }
        .onMapCameraChange(frequency: .onEnd) { _ in
          refreshPins(using: proxy)
        }
        .onChange(of: albums.map(AlbumMapLocationSnapshot.init)) { _, _ in
          refreshPins(using: proxy)
        }
        .onAppear {
          centerOnLatest()
          refreshPins(using: proxy)
        }
        .mapControlVisibility(.hidden)
        .overlay {
          if albums.isEmpty {
            ContentUnavailableView(
              "No albums yet",
              systemImage: "map",
              description: Text("Albums with captured locations will appear here."),
            )
          } else if albums.allSatisfy({ $0.mapCoordinate == nil }) {
            ContentUnavailableView(
              "No album locations",
              systemImage: "location.slash",
              description: Text("Albums need a captured location to appear on the map."),
            )
          }
        }
        .toolbar {
          ToolbarTitle("Spatial")

          ToolbarItemGroup(placement: .topBarTrailing) {
            let disabled = albums.allSatisfy { $0.mapCoordinate == nil }

            Button("Show All", systemImage: "arrow.up.left.and.arrow.down.right") {
              showAll()
            }
            .disabled(disabled)

            Button("Latest", systemImage: "location.fill") {
              centerOnLatest()
            }
            .disabled(disabled)
          }
        }
        .sheet(item: $selectedCluster) { pin in
          AlbumClusterSheet(pin: pin)
        }
        .sheet(item: $selectedAlbum) { album in
          AlbumDetailSheet(album: album)
        }
      }
    }
  }

  private func refreshPins(using proxy: MapProxy) {
    model.updatePins(for: albums) { proxy.convert($0, to: .local) }
  }

  private func centerOnLatest() {
    guard let coordinate = albums.lazy.compactMap(\.mapCoordinate).first
    else { return }

    position = .region(
      MKCoordinateRegion(
        center: coordinate,
        latitudinalMeters: 2_000,
        longitudinalMeters: 2_000,
      )
    )
  }

  private func showAll() {
    let coordinates = albums.compactMap(\.mapCoordinate)
    guard let first = coordinates.first else { return }

    var rect = MKMapRect(
      origin: MKMapPoint(first),
      size: MKMapSize(width: 0, height: 0),
    )

    for coordinate in coordinates.dropFirst() {
      let point = MKMapPoint(coordinate)
      rect = rect.union(
        MKMapRect(
          origin: point,
          size: MKMapSize(width: 0, height: 0),
        )
      )
    }

    if coordinates.count == 1 {
      centerOnLatest()
    } else {
      position = .rect(
        rect.insetBy(
          dx: -rect.width * 0.3,
          dy: -rect.height * 0.3,
        )
      )
    }
  }
}

private struct AlbumMapLocationSnapshot: Equatable {
  let id: UUID
  let latitude: Double?
  let longitude: Double?

  init(_ album: Album) {
    id = album.id
    latitude = album.latitude
    longitude = album.longitude
  }
}

extension Album {
  var mapCoordinate: CLLocationCoordinate2D? {
    guard
      let latitude,
      let longitude,
      latitude.isFinite,
      longitude.isFinite
    else { return nil }

    let coordinate = CLLocationCoordinate2D(
      latitude: latitude,
      longitude: longitude,
    )

    return CLLocationCoordinate2DIsValid(coordinate)
      ? coordinate
      : nil
  }
}

private struct AlbumClusterSheet: View {
  let pin: AlbumMapPin

  @State private var selectedAlbum: Album?

  var body: some View {
    NavigationStack {
      AlbumClusterView(albums: pin.albums) { album in
        selectedAlbum = album
      }
      .sheet(item: $selectedAlbum) { album in
        AlbumDetailSheet(album: album)
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("\(pin.albums.count) albums")
            .font(.zillaSlab(.headline).bold())
            .foregroundStyle(.primary)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .presentationDetents([.medium, .large])
      .sheetCloseButton()
    }
  }
}

private struct AlbumDetailSheet: View {
  let album: Album

  var body: some View {
    NavigationStack {
      AlbumDetailView(album: album)
        .presentationDetents([.large])
        .sheetCloseButton()
    }
  }
}

struct SheetCloseButton: ViewModifier {
  @Environment(\.dismiss) private var dismiss

  func body(content: Content) -> some View {
    content
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .cancel) {
            dismiss()
          }
        }
      }
  }
}

extension View {
  func sheetCloseButton() -> some View {
    modifier(SheetCloseButton())
  }
}

#if DEBUG
#Preview("Cluster", traits: .withSearchContext) {
  AlbumMapView()
}
#endif
