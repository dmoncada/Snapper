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
  let entry: AlbumEntry

  @State private var vm = AlbumDetailViewModel2()
  @State private var tracks: [AlbumTrack] = []

  var body: some View {
    ScrollView(.vertical) {
      VStack(spacing: .zero) {
        AlbumCover(url: URL(string: entry.coverImageUrlString ?? ""))

        VStack(alignment: .leading, spacing: Spacing.sm) {
          Text(entry.title)
            .font(.sligoilMicroBold(.headline))
            .foregroundStyle(.themePrimaryInverted)

          Text(entry.artist)
            .font(.sligoilMicro(.subheadline))
            .foregroundStyle(.themeRed)

          Spacer(minLength: Spacing.md)
          AlbumDetailSection(entry: entry)

          Spacer(minLength: Spacing.md)
          AlbumTrackSection(tracks: tracks)
        }
        .padding()
      }
    }
    .task {
      if let tracks = try? await vm.resolveTracks(for: entry) {
        print("Resolved: \(tracks.tracks.count) tracks (\(tracks.source.title))")
        self.tracks = tracks.tracks
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
    AsyncImage(url: url) { phase in
      switch phase {
      case .empty:
        ZStack {
          Color.gray
          ProgressView()
            .tint(.white)
        }

      case .success(let image):
        image
          .resizable()
          .scaledToFill()

      case .failure:
        Color.gray

      @unknown default:
        Color.gray
      }
    }
    .asyncImageURLSession(.images)
    .frame(maxWidth: .infinity)
    .frame(height: height)
    .clipped()
  }
}

private struct AlbumDetailSection: View {
  let entry: AlbumEntry

  var body: some View {
    Section {
      VStack(alignment: .leading) {
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

    } header: {
      Text("About")
        .font(.libreCaslonTextBold(.headline))
        .foregroundStyle(.themePrimaryInverted)
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
    if tracks.isEmpty {
      ProgressView()

    } else {
      Section {
        ForEach(tracks) { track in
          AlbumTrackRow2(track)
          Divider()
        }

      } header: {
        Text("Tracks")
          .font(.libreCaslonTextBold(.headline))
          .foregroundStyle(.themePrimaryInverted)
      }
    }
  }
}

private struct AlbumTrackRow2: View {
  let track: AlbumTrack

  init(_ track: AlbumTrack) {
    self.track = track
  }

  var body: some View {
    HStack {
      Button("Play", systemImage: "play.circle") {}
        .labelStyle(.iconOnly)

      Text(track.title)
        .font(.sligoilMicroBold(.subheadline))
        .minimumScaleFactor(0.75)
        .lineLimit(1)

      Spacer()

      Text(track.duration ?? "N/A")
        .font(.sligoilMicro(.subheadline))
    }
    .foregroundStyle(.themePrimaryInverted)
    .opacity(0.625)
  }
}

#if DEBUG
  import SwiftData

  #Preview(traits: .withSampleData) {
    @Previewable @Query var entries: [AlbumEntry]

    if entries.count > 0 {
      AlbumDetailView2(entry: entries[0])

    } else {
      ProgressView()
    }
  }
#endif
