import SwiftUI

struct AlbumLocationDescription: View {
  let entry: AlbumHistoryEntry

  var body: some View {
    if let latitude = entry.latitude, let longitude = entry.longitude {
      VStack(alignment: .leading) {
        if let locationLabel = entry.locationLabel {
          Text(locationLabel)
            .bold()
        }

        Text(
          "\(latitude.formatted(.number.precision(.fractionLength(4)))), \(longitude.formatted(.number.precision(.fractionLength(4))))"
        )
        .foregroundStyle(.secondary)

        if let horizontalAccuracy = entry.horizontalAccuracy {
          Text("Accuracy ±\(horizontalAccuracy.formatted(.number.precision(.fractionLength(0)))) m")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
      }
    } else {
      Text("No location saved")
        .foregroundStyle(.secondary)
    }
  }
}
