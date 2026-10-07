import MapKit
import SwiftUI

struct AlbumDetailView: View {
  @Environment(PreviewPlayer.self) private var player

  let entry: AlbumEntry
  let showMetadata: Bool

  init(entry: AlbumEntry, showMetadata: Bool = true) {
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
          AlbumHeaderSection(entry: entry)
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

private struct AlbumHeaderSection: View {
  let entry: AlbumEntry

  var body: some View {
    HStack(alignment: .top) {
      AlbumHeader(entry: entry, size: .large)

      Spacer()

      Icon(systemName: "star.fill", size: 24)
        .foregroundStyle(.accent)
        .symbolEffect(.bounce.up, options: .speed(2), value: entry.isFavorited)
        .opacity(entry.isFavorited ? 1 : 0)
    }
  }
}

private struct AlbumDetailSection: View {
  let entry: AlbumEntry
  let showMetadata: Bool

  var body: some View {
    ThemeSection {
      Section("About") {
        if let label = entry.labels.first {
          LabeledContent("Label", value: label)
        }

        if let year = entry.year?.description {
          LabeledContent("Released", value: year)
        }

        if showMetadata {
          LabeledContent("Recognized", value: entry.selectedAt.abbreviated)
          LocationSection(entry: entry)
        }
      }
    }
    .labeledContentStyle(.withThemeFont)
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
      LabeledContent {
        ProgressView()
          .controlSize(.small)
      } label: {
        Text("Location")
      }

    case .captured:
      if let location = entry.location {
        DisclosureGroup(isExpanded: $isExpanded) {
          MapView(
            location: location,
            accuracyRadius: entry.locationHorizontalAccuracy,
          )
        } label: {
          Text("Location")
            .font(.sligoilMicroBold(.subheadline))
        }
        .disclosureGroupStyle(.plain)
      } else {
        LabeledContent("Location", value: "No Location")
      }

    case .denied, .unavailable:
      LabeledContent("Location", value: "No Location")
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
            .foregroundStyle(.themeBlue.opacity(0.25))
            .stroke(.themeBlue.opacity(0.5), lineWidth: 1)
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

private struct AlbumTrackSection: View {
  let tracks: [AlbumTrack]

  var body: some View {
    ThemeSection {
      if tracks.isEmpty {
        Section("Tracks") {
          ProgressView()
        }
      } else {
        Section {
          ForEach(tracks) { track in
            AlbumTrackRow(track: track)
          }
        } header: {
          Text("Tracks")
        } footer: {
          let anyPreview = tracks.contains { $0.previewUrl != nil }
          if anyPreview {
            Text("Tracks provided courtesy of iTunes.")
          }
        }
      }
    }
  }
}

private struct AlbumTrackRow: View {
  @Environment(PreviewPlayer.self) private var player

  let track: AlbumTrack

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
      LabeledContent {
        Text(track.duration ?? "N/A")
      } label: {
        HStack(spacing: Spacing.sm) {
          Group {
            if track.previewUrl == nil {
              Icon(systemName: "play.slash")
            } else {
              PlaybackIndicator(isPlaying: isPlaying, progress: player.progress)
            }
          }
          .frame(width: 24)

          Text(track.title)
            .lineLimit(1)
        }
      }
    }
    .buttonStyle(.plain)
    .labeledContentStyle(.withThemeFont(isActive: isPlaying))
    .animation(.easeInOut, value: isPlaying)
    .disabled(track.previewUrl == nil)
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
