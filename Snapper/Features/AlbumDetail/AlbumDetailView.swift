import MapKit
import SwiftUI

struct AlbumDetailView: View {
  @Environment(PreviewPlayer.self) private var player

  let entry: AlbumEntry
  let showMetadata: Bool

  init(entry: AlbumEntry, showMetadata: Bool = false) {
    self.entry = entry
    self.showMetadata = showMetadata
  }

  @State private var vm = AlbumDetailViewModel()

  var body: some View {
    ScrollView(.vertical) {
      VStack(spacing: 0) {
        AlbumCover(url: URL(string: entry.coverImageUrlString ?? ""))
          .stretchable()

        VStack(alignment: .leading, spacing: Padding.xxl) {
          AlbumHeader(entry: entry, size: .lg)
          AlbumDetailSection(entry: entry, showMetadata: showMetadata)
          AlbumTrackSection(tracks: vm.tracks)
        }
        .padding(Padding.xl)
      }
      .containerRelativeFrame(.horizontal)
    }
    .task {
      await vm.materialize(entry)
    }
    .onDisappear {
      Task {
        await player.stopImmediately()
      }
    }
    .ignoresSafeArea(.all, edges: .top)
    .fullBackground(.themePrimary)
  }
}

private struct AlbumCover: View {
  let url: URL?
  let height: CGFloat

  init(url: URL?, height: CGFloat = 300) {
    self.url = url
    self.height = height
  }

  var body: some View {
    CachedImage(url: url)
      .frame(maxWidth: .infinity)
      .frame(height: height)
      .clipped()
  }
}

private struct AlbumDetailSection: View {
  let entry: AlbumEntry
  let showMetadata: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: Padding.xl) {
      SectionHeader("About")
      Section {
        VStack(spacing: Spacing.sm) {
          if let label = entry.labels.first {
            AlbumDetailRow("Label", label)
            Divider()
          }

          if let year = entry.year?.description {
            AlbumDetailRow("Released", year)
            Divider()
          }

          if showMetadata {
            AlbumDetailRow("Recognized", entry.selectedAt.abbreviated)
            Divider()

            LocationSection(entry: entry)
              .frame(minHeight: 12)  // TODO(dmoncada): figure out how to set all rows to the same height.
          }
        }
      }
    }
  }
}

extension Date {
  fileprivate var abbreviated: String {
    formatted(date: .abbreviated, time: .shortened)
  }
}

private struct LocationSection: View {
  let entry: AlbumEntry

  @State private var isExpanded = false

  var body: some View {
    switch entry.locationStatus {
    case .pending:
      HStack {
        Text("Location").font(.sligoilMicroBold(.subheadline))
        Spacer()
        ProgressView()
      }
      .foregroundStyle(.themePrimaryInverted)
      .opacity(0.625)

    case .captured:
      if let location = entry.location {
        DisclosureGroup(isExpanded: $isExpanded) {
          MapView(
            location: location,
            accuracyRadius: entry.locationHorizontalAccuracy,
          )
        } label: {
          Group {
            if (entry.locationHorizontalAccuracy ?? 0) >= 1_000 {
              Text("Approximate Location")
            } else {
              Text("Location")
            }
          }
          .font(.sligoilMicroBold(.subheadline))
        }
        .disclosureGroupStyle(.plain)
        .opacity(0.625)
      } else {
        AlbumDetailRow("Location", "No Location")
      }

    case .denied, .unavailable:
      AlbumDetailRow("Location", "No Location")
    }
  }
}

private struct MapView: View {
  let location: CLLocation
  let accuracyRadius: Double?

  @State private var position: MapCameraPosition = .automatic

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      Map(position: $position) {
        if let accuracyRadius, accuracyRadius > 0 {
          MapCircle(center: location.coordinate, radius: accuracyRadius)
            .foregroundStyle(.themeBlue.opacity(0.15))
            .stroke(.themeBlue.opacity(0.55), lineWidth: 1)
        }
        Marker("Location", coordinate: location.coordinate)
      }
      .frame(height: 200)
      .clipShape(.rect(cornerRadius: Radius.md))

      Button("Re-center", systemImage: "location.fill") {
        withAnimation(.easeInOut(duration: 0.5)) {
          recenter()
        }
      }
      .padding(Padding.md)
      .labelStyle(.iconOnly)
      .glassEffect(.regular.tint(.themeBlue.opacity(0.25)))
      .offset(x: -8, y: -8)
    }
    .onAppear {
      recenter()
    }
  }

  private func recenter() {
    if let accuracyRadius, accuracyRadius > 0 {
      let visibleDistance = max(15_000, accuracyRadius * 3)

      position = .region(
        MKCoordinateRegion(
          center: location.coordinate,
          latitudinalMeters: visibleDistance,
          longitudinalMeters: visibleDistance,
        )
      )
    } else {
      position = location.position
    }
  }
}

private struct AlbumDetailRow: View {
  let key: String
  let value: String

  init(_ key: String, _ value: String) {
    self.key = key
    self.value = value
  }

  var body: some View {
    HStack {
      Text(key).font(.sligoilMicroBold(.subheadline))
      Spacer()
      Text(value).font(.sligoilMicro(.subheadline))
    }
    .foregroundStyle(.themePrimaryInverted)
    .opacity(0.625)
  }
}

private struct AlbumTrackSection: View {
  let tracks: [AlbumTrack]

  var body: some View {
    VStack(alignment: .leading, spacing: Padding.xl) {
      SectionHeader("Tracks")
      Section {
        if tracks.isEmpty {
          ProgressView()
        } else {
          VStack(spacing: Spacing.sm) {
            ForEach(tracks.enumerated(), id: \.offset) { i, track in
              AlbumTrackRow(track)
              if i < tracks.count - 1 {
                Divider()
              }
            }
          }
        }
      }
    }
  }
}

private struct AlbumTrackRow: View {
  @Environment(PreviewPlayer.self) private var player

  let track: AlbumTrack

  init(_ track: AlbumTrack) {
    self.track = track
  }

  var body: some View {
    let isPlaying = track.title == player.preview?.title

    Button {
      guard let url = track.previewUrl else { return }
      Task {
        isPlaying
          ? await player.stopImmediately()
          : await player.play(url, title: track.title)
      }
    } label: {
      HStack {
        Group {
          if track.previewUrl == nil {
            Image(systemName: "play.slash")
          } else {
            PlaybackIndicator(isPlaying: isPlaying, progress: player.progress)
          }
        }
        .frame(width: 24)

        Text(track.title)
          .font(.sligoilMicroBold(.subheadline))
          .minimumScaleFactor(0.75)
          .lineLimit(1)

        Spacer()

        Text(track.duration ?? "N/A")
          .font(.sligoilMicro(.subheadline))
      }
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .allowsHitTesting(track.previewUrl != nil)
    // .disabled(track.previewUrl == nil)
    .foregroundStyle(
      isPlaying
        ? .accent
        : .themePrimaryInverted
    )
    .animation(
      .easeInOut(duration: 0.25),
      value: isPlaying,
    )
    .opacity(0.625)
  }
}

#if DEBUG
import SwiftData

#Preview(traits: .withSampleData) {
  @Previewable @Query(sort: \AlbumEntry.selectedAt) var entries: [AlbumEntry]
  @Previewable @State var player = PreviewPlayer()

  if entries.count > 0 {
    let entry = entries[0]
    NavigationStack {
      AlbumDetailView(entry: entry)
        .environment(player)
    }
  } else {
    ProgressView()
  }
}
#endif
