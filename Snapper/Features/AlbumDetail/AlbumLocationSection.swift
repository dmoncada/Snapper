import MapKit
import SwiftUI

struct AlbumLocationSection: View {
  let location: CLLocation

  @State private var position: MapCameraPosition = .automatic
  @State private var locationName: String?
  @State private var isExpanded = true

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.xs) {
      DisclosureGroup(isExpanded: $isExpanded) {
        Map(position: $position, interactionModes: [.pan, .zoom]) {
          Marker(.detailSectionsLocationMarker, coordinate: location.coordinate)
            .tint(.accent)
        }
        .frame(height: 200)
        .overlay(alignment: .bottomTrailing) {
          VStack {
            Button("Re-center", systemImage: "location.fill") {
              withAnimation(.easeInOut(duration: 0.375)) {
                recenter()
              }
            }
            .padding(Padding.md)
            .labelStyle(.iconOnly)
            .foregroundStyle(.themePrimaryActive)
            .glassEffect(.clear.tint(.themeSurface1))
          }
          .padding(Padding.lg)
        }
      } label: {
        VStack(alignment: .leading, spacing: 0) {
          Text(.detailSectionsLocationHeader)
            .font(.zillaSlab(.headline).bold())

          if let locationName {
            Text(.detailSectionsLocationCaption(locationName: locationName))
              .font(.gillSans(.caption))
          }
        }
      }
      .disclosureGroupStyle(.theme(.surface1))

      NearbyRecordStoresView(location: location)
    }
    .onChange(of: isExpanded, initial: true) { _, newValue in
      if newValue {
        recenter()
      }
    }
    .task {
      if locationName == nil {
        locationName = try? await ApproximateLocation.getName(location)
      }
    }
  }

  private func recenter() {
    position = location.position
  }
}

private struct NearbyRecordStoresView: View {
  private enum State {
    case ready
    case loading
    case loaded([RecordStoreCandidate])
    case failed(Error)
  }

  @Environment(\.recordStoreLocator) private var locator

  let location: CLLocation

  @State private var state: State = .ready
  @State private var selection = StoreSelection()

  var body: some View {
    Group {
      switch state {
      case .ready, .loading:
        loadingView

      case .failed(_):
        retryView

      case .loaded(let stores) where stores.isEmpty:
        retryView

      case .loaded(let stores):
        HStack(spacing: Spacing.sm) {
          Text(.detailSectionsLocationNearby)
            .font(.gillSans(.caption))

          ScrollView(.horizontal) {
            HStack(spacing: Spacing.xs) {
              ForEach(stores) { store in
                RecordStoreToggle(
                  location: location,
                  candidate: store,
                  selection: selection,
                )
              }
            }
            .padding(1)
          }
          .scrollIndicators(.hidden)
        }
      }
    }
    .frame(minHeight: 32)
    .task {
      await locateStores()
    }
  }

  private var loadingView: some View {
    ProgressView(.detailSectionsLocationStateLoading)
      .progressViewStyle(.inline(.trailing))
      .font(.gillSans(.caption))
      .controlSize(.small)
  }

  private var retryView: some View {
    HStack(spacing: Spacing.sm) {
      Text(.detailSectionsLocationStateFailed)
        .font(.gillSans(.caption))

      Button {
        Task {
          await locateStores()
        }
      } label: {
        Text(.detailSectionsLocationRetry)
          .badgeStyle(appearance: .highlighted)
          .controlSize(.small)
      }
      .buttonStyle(.plain)
    }
  }

  private func locateStores() async {
    state = .loading
    do {
      let stores = try await locator.locate(
        near: location,
        within: .kilometers(5),
        limit: 3,
      )
      state = .loaded(stores)
    } catch {
      state = .failed(error)
    }
  }
}

#if DEBUG
#Preview("Fail") {
  let location: LocationStub = .newYork

  AlbumLocationSection(location: location.location)
    .environment(\.recordStoreLocator, .fail(delay: .seconds(1)))
    .padding()
}

#Preview("Live") {
  let logger = PreviewLoggerFactory.makeLogger("playground")
  let location: LocationStub = .newYork

  AlbumLocationSection(location: location.location)
    .environment(\.recordStoreLocator, .live(logger))
    .padding()
}
#endif
