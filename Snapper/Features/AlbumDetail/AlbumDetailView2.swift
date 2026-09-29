import MapKit
import SwiftUI

nonisolated struct AlbumTracklist: Sendable, Hashable {
  let tracks: [AlbumTrack]
  let source: AlbumTracklistSource
}

nonisolated enum AlbumTracklistSource: Sendable, Hashable {
  case itunes(URL?)
  case discogs

  var title: String {
    switch self {
    case .itunes:
      "Tracks and previews from iTunes"
    case .discogs:
      "Tracklist from Discogs"
    }
  }

  var itunesUrl: URL? {
    guard case .itunes(let url) = self else { return nil }
    return url
  }
}

nonisolated struct AlbumTracklistResolver: Sendable {
  private let discogsClient: DiscogsClient
  private let itunesClient: ItunesClient

  init(
    discogsClient: DiscogsClient,
    itunesClient: ItunesClient,
  ) {
    self.discogsClient = discogsClient
    self.itunesClient = itunesClient
  }

  func resolve(_ entry: AlbumEntry) async throws -> AlbumTracklist {
    let candidate = AlbumCandidate(
      id: 0,
      artist: entry.artist,
      title: entry.title,
      year: nil,
      formats: [],
      labels: [],
      country: nil,
      thumbnailUrl: nil,
      coverImageUrl: nil,
      discogsUrl: nil
    )

    if let tracklist = try await itunesClient.tracklist(for: candidate, barcode: nil) {
      return AlbumTracklist(
        tracks: tracklist.tracks.map { track in
          AlbumTrack(
            id: "itunes-\(track.id)",
            position: "\(track.discNumber)-\(track.trackNumber)",
            title: track.title,
            duration: track.duration,
            previewUrl: track.previewUrl)
        },
        source: .itunes(tracklist.collectionUrl)
      )
    }

    let tracks = try await discogsClient.tracklist(forReleaseId: entry.discogsReleaseId)

    return AlbumTracklist(tracks: tracks, source: .discogs)
  }
}

@MainActor
@Observable
private class AlbumDetailViewModel2 {
  private let resolver: AlbumTracklistResolver

  init() {
    let token = Bundle.main.object(forInfoDictionaryKey: "DISCOGS_TOKEN") as? String ?? ""

    resolver = .init(
      discogsClient: .init(token: token),
      itunesClient: .init()
    )
  }

  func resolveTracks(for entry: AlbumEntry) async throws -> AlbumTracklist {
    return try await resolver.resolve(entry)
  }
}

struct AlbumDetailView2: View {
  @Environment(PreviewPlayer.self) private var player

  let entry: AlbumEntry

  @State private var vm = AlbumDetailViewModel2()
  @State private var tracks: [AlbumTrack] = []

  var body: some View {
    ScrollView(.vertical) {
      VStack(spacing: 0) {
        AlbumCover(url: URL(string: entry.coverImageUrlString ?? ""))

        VStack(alignment: .leading, spacing: Padding.xxl) {
          AlbumHeader(entry: entry, size: .lg)
          AlbumDetailSection(entry: entry)
          AlbumTrackSection(tracks: tracks)
        }
        .padding()
      }
    }
    .task {
      if let tracks = try? await vm.resolveTracks(for: entry) {
        print("Resolved: \(tracks.tracks.count) tracks (\(tracks.source.title))")
        for track in tracks.tracks { print(track.previewUrl ?? "") }
        self.tracks = tracks.tracks
      }
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

          AlbumDetailRow("Recognized", entry.selectedAt.abbreviated)
          Divider()

          LocationSection(entry: entry)
          // Divider()
        }
      }
    }
  }
}

extension Date {
  fileprivate var abbreviated: String {
    return self.formatted(date: .abbreviated, time: .shortened)
  }
}

struct LocationSection: View {
  let entry: AlbumEntry

  @State private var isExpanded = false

  var body: some View {
    if let location = entry.location, let position = entry.position {
      DisclosureGroup(isExpanded: $isExpanded) {
        Map(position: .constant(position)) {
          Marker("Location", coordinate: location.coordinate)
        }
        .frame(height: 200)
        .clipShape(.rect(cornerRadius: Radius.md))

      } label: {
        Text("Location")
          .font(.sligoilMicroBold(.subheadline))
      }
      .disclosureGroupStyle(.plain)
      .opacity(0.625)

    } else {
      AlbumDetailRow("Location", "No Location")
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
      Text(key)
        .font(.sligoilMicroBold(.subheadline))

      Spacer()

      Text(value)
        .font(.sligoilMicro(.subheadline))
    }
    .foregroundStyle(.themePrimaryInverted)
    .opacity(0.625)
  }
}

struct AlbumTrackSection: View {
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
              AlbumTrackRow2(track)
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

private struct AlbumTrackRow2: View {
  @Environment(PreviewPlayer.self) private var player

  let track: AlbumTrack

  init(_ track: AlbumTrack) {
    self.track = track
  }

  var body: some View {
    let disabled = track.previewUrl == nil
    let isPlaying = track.title == player.preview?.title

    HStack {
      PlaybackButton(isPlaying: isPlaying) {
        guard let url = track.previewUrl else { return }
        Task {
          isPlaying
            ? await player.stopImmediately()
            : await player.play(url, title: track.title)
        }
      }
      .disabled(disabled)

      Text(track.title)
        .font(.sligoilMicroBold(.subheadline))
        .minimumScaleFactor(0.75)
        .lineLimit(1)

      Spacer()

      Text(track.duration ?? "N/A")
        .font(.sligoilMicro(.subheadline))
    }
    .foregroundStyle(
      isPlaying
        ? .themeRed
        : .themePrimaryInverted
    )
    .animation(
      .easeInOut(duration: 0.25),
      value: isPlaying
    )
    .opacity(0.625)
  }
}

#if DEBUG
  import SwiftData

  #Preview(traits: .withSampleData) {
    @Previewable @Query var entries: [AlbumEntry]
    @Previewable @State var player = PreviewPlayer()

    if let entry = entries.first {
      AlbumDetailView2(entry: entry)
        .environment(player)

    } else {
      ProgressView()
    }
  }
#endif
