import SwiftUI

@Observable
final class StoreSelection {
  var selectedStoreId: RecordStoreCandidate.ID?

  subscript(isSelected storeId: RecordStoreCandidate.ID) -> Bool {
    get { selectedStoreId == storeId }
    set { selectedStoreId = newValue ? storeId : nil }
  }
}

struct RecordStoreToggle: View {
  @Environment(\.locale) private var locale

  let location: CLLocation
  let candidate: RecordStoreCandidate

  @Bindable var selection: StoreSelection

  var body: some View {
    let distance = Measurement(
      value: candidate.distance(from: location),
      unit: UnitLength.meters,
    )

    return Toggle(isOn: $selection[isSelected: candidate.id]) {
      Label {
        HStack(spacing: Spacing.xs) {
          Text(candidate.name)
          Text("•")
          Text(
            distance.formatted(
              .measurement(width: .narrow, usage: .road)
                .locale(locale)
            )
          )
          .font(.zillaSlab(.caption).weight(.ultraLight))
        }
      } icon: {
        Image(systemName: "mappin.and.ellipse")
      }
    }
    .toggleStyle(
      .titleAndIconBadge(
        labelStyle: .expand,
        appearance: selection[isSelected: candidate.id]
          ? .highlighted
          : .default,
      )
    )
    .controlSize(.small)
    .imageScale(.small)
  }
}

#if DEBUG
import SwiftData

private struct RecordStoreTogglePreview: View {
  @Query(sort: \Album.selectedAt, order: .reverse) private var albums: [Album]

  @State private var stores: [RecordStoreCandidate] = []
  @State private var selection = StoreSelection()

  var body: some View {
    Group {
      if let album = albums.last,
        let location = album.location,
        stores.isEmpty == false
      {
        WithColorSchemes(axis: .horizontal) {
          VStack {
            if let store = stores.dropFirst(0).first {
              RecordStoreToggle(location: location, candidate: store, selection: selection)
                .environment(\.locale, Locale(identifier: "en-US-u-ms-ussystem"))
            }

            if let store = stores.dropFirst(1).first {
              RecordStoreToggle(location: location, candidate: store, selection: selection)
                .environment(\.locale, Locale(identifier: "en-US-u-ms-metric"))
            }

            if let store = stores.dropFirst(2).first {
              RecordStoreToggle(location: location, candidate: store, selection: selection)
                .environment(\.locale, Locale(identifier: "de"))
            }
          }
          .frame(maxWidth: .infinity)
          .padding()
        }
      } else {
        ProgressView()
      }
    }
    .task {
      guard
        let album = albums.last,
        let location = album.location,
        let stores = try? await RecordStoreLocator.findNearby(
          near: location,
          within: .meters(500),
          limit: 3,
        )
      else { return }

      self.stores = stores
    }
  }
}

#Preview(traits: .withSearchContext) {
  RecordStoreTogglePreview()
}

#endif
