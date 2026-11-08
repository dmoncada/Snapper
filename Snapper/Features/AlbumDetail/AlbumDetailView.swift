import MapKit
import SwiftData
import SwiftUI

struct AlbumDetailView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.previewPlayer) private var player

  @Environment(AlbumDetailViewModel.self) private var vm

  let album: Album
  let showMetadata: Bool

  init(album: Album, showMetadata: Bool = true) {
    self.album = album
    self.showMetadata = showMetadata
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        AlbumCover(url: album.coverImageUrl)
          .stretchable()

        VStack(alignment: .leading, spacing: Padding.xxl) {
          AlbumHeaderSection(album: album, showMetadata: showMetadata)
          AlbumDetailSection(album: album, showMetadata: showMetadata)
          AlbumTrackSection(vm: vm, musicUrl: album.musicUrl)
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
    .withFullBackground()
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
      .scaledToFill()
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

    HStack(alignment: .firstTextBaseline) {
      LabeledContent {
        Text(album.title)
          .font(Typography.albumDetailTitle)
      } label: {
        Text(album.artist)
          .font(Typography.albumDetailArtist)
      }
      .labeledContentStyle(.albumHeader)

      Spacer()

      FavoriteIconButton(isFavorite: $album.isFavorite)
        .foregroundStyle(.accent)
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

  var body: some View {
    switch locationStatus {
    case .pending:
      LabeledContent("Location") {
        ProgressView()
          .controlSize(.small)
      }

    case .captured:
      if let location = location {
        DisclosureGroup("Location") {
          MapView(location: location)
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
  let musicUrl: URL?

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
            AlbumTrackSectionFooter(musicUrl: musicUrl)
          }
        }
      }
    }
  }
}

private struct AlbumTrackSectionFooter: View {
  let musicUrl: URL?

  var body: some View {
    VStack(alignment: .leading) {
      Text("Tracks provided courtesy of iTunes.")

      if let musicUrl {
        Spacer()

        Link(destination: musicUrl) {
          Image(.appleMusicBadge)
            .resizable()
            .scaledToFit()
            .frame(height: 32)
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
        ProgressView(value: player.progress)
          .progressViewStyle(.playback(isPlaying: isPlaying))

        LabeledContent(track.title, value: track.duration)
      }
      .foregroundStyle(
        isPlaying ? .accent : .themePrimary,
        isPlaying ? .accent : .themeSecondary,
      )
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .animation(.easeInOut, value: isPlaying)
    .disabled(track.previewUrl == nil)
  }
}

#if DEBUG
import SwiftData

#Preview(traits: .withSearchContext) {
  @Previewable @Query(sort: \Album.selectedAt, order: .reverse) var albums: [Album]

  if let album = albums.first {
    AlbumDetailView(album: album)
  } else {
    ProgressView()
  }
}
#endif
