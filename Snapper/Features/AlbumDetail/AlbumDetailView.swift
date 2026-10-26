import MapKit
import SwiftData
import SwiftUI

struct AlbumDetailView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.previewPlayer) private var player

  let album: Album
  let showMetadata: Bool

  init(album: Album, showMetadata: Bool = true) {
    self.album = album
    self.showMetadata = showMetadata
  }

  @State private var vm = AlbumDetailViewModel()

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        AlbumCover(url: album.coverImageUrl)
          .stretchable()

        VStack(alignment: .leading, spacing: Padding.xxl) {
          AlbumHeaderSection(album: album, showMetadata: showMetadata)
          AlbumDetailSection(album: album, showMetadata: showMetadata)
          AlbumTrackSection(vm: vm)
        }
        .padding(Padding.xl)
      }
      .containerRelativeFrame(.horizontal)
    }
    .task {
      await vm.resolveTracks(for: album)
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

  init(
    url: URL?,
    height: CGFloat = 300,
  ) {
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
  let album: Album
  let showMetadata: Bool

  var body: some View {
    @Bindable var album = album

    HStack(alignment: .top) {
      AlbumHeader(title: album.title, artist: album.artist, size: .large)

      Spacer()

      FavoriteIconButton(isFavorite: $album.isFavorite)
        .disabled(showMetadata == false)
        .opacity(showMetadata ? 1 : 0)
    }
  }
}

private struct AlbumDetailSection: View {
  let album: Album
  let showMetadata: Bool

  var body: some View {
    ThemeSection {
      Section("About") {
        if let label = album.label.first {
          LabeledContent("Label", value: label)
        }

        if let year = album.year?.description {
          LabeledContent("Released", value: year)
        }

        if let country = album.countryName {
          LabeledContent("Country", value: country)
        }

        if showMetadata {
          LabeledContent("Recognized", value: album.selectedAt.abbreviated)
          LocationSection(location: album.location, locationStatus: album.locationStatus)
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
  let location: CLLocation?
  let locationStatus: AlbumLocationStatus

  @State private var isExpanded = false

  var body: some View {
    switch locationStatus {
    case .pending:
      LabeledContent {
        ProgressView()
          .controlSize(.small)
      } label: {
        Text("Location")
      }

    case .captured:
      if let location = location {
        DisclosureGroup(isExpanded: $isExpanded) {
          MapView(location: location)
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

  init(location: CLLocation, accuracyRadius: Double? = nil) {
    self.location = location
    self.accuracyRadius = accuracyRadius
  }

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
  let vm: AlbumDetailViewModel

  var body: some View {
    ThemeSection {
      switch vm.state {
      case .ready:
        Text("Ready to load.")

      case .loading:
        ProgressView()

      case .cancelled:
        Text("Loading cancelled.")

      case .failure(let error):
        Text("Unable to load tracks: \(error)")

      case .success(let tracks) where tracks.isEmpty:
        Text("Unable to load tracks.")

      case .success(let tracks):
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
  @Environment(\.previewPlayer) private var player

  let track: Track

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
      HStack(spacing: Spacing.sm) {
        HStack(spacing: Spacing.sm) {
          PlaybackIndicator(isPlaying: isPlaying, progress: player.progress)

          // Text(track.position)

          Text(track.title)
            .lineLimit(1)
        }
        .font(.sligoilMicroBold(.subheadline))

        Spacer()

        Text(track.duration)
          .font(.sligoilMicro(.subheadline))
      }
      .contentShape(.rect)
      .foregroundStyle(
        isPlaying
          ? .accent
          : .themePrimaryInverted
      )
      .opacity(isPlaying ? 1 : 0.625)
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
  @Previewable @Query(sort: \Album.selectedAt, order: .reverse) var albums: [Album]

  if let album = albums.first {
    NavigationStack {
      AlbumDetailView(album: album)
        .environment(\.previewPlayer, .live)
    }
  } else {
    ProgressView()
  }
}
#endif
