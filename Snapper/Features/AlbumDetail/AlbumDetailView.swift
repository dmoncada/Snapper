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

        VStack(alignment: .leading, spacing: Spacing.lg) {
          AlbumHeaderSection(album: album, showMetadata: showMetadata)

          if showMetadata, album.artistInfo.hasInfo {
            AlbumWikipediaSection(album.artistInfo.get())
          }

          if showMetadata, album.albumInfo.hasInfo {
            AlbumWikipediaSection(album.albumInfo.get())
          }

          if showMetadata, let location = album.location {
            AlbumLocationSection(location: location)
          }

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
    .scrollIndicators(.hidden)
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

    VStack(spacing: Spacing.md) {
      HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
        VStack(alignment: .leading, spacing: Spacing.xs) {
          Text(album.title)
            .font(Typography.albumDetail.title)
            .foregroundStyle(.themePrimary)

          Text(album.artist)
            .font(Typography.albumDetail.artist)
            .foregroundStyle(.accent)
        }

        Spacer()

        Toggle("Favorite", isOn: $album.isFavorite)
          .toggleStyle(.favoriteIcon)
          .foregroundStyle(.accent)
          .disabled(showMetadata == false)
          .opacity(showMetadata ? 1 : 0)
      }

      AlbumGenresSection(genres: album.genre)
    }
  }
}

private struct AlbumGenresSection: View {
  init(genres: [Genre]) {
    self.genres = genres.map(\.name).sorted()
  }

  private let genres: [String]

  var body: some View {
    FlowLayout(alignment: .leading, spacing: Spacing.xs) {
      ForEach(genres, id: \.self) { genre in
        Text(genre)
          .badgeStyle()
          .controlSize(.small)
      }
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
          LabeledContent {
            VStack(alignment: .trailing, spacing: Spacing.xs) {
              Text(album.selectedAt, format: .relative(presentation: .named))
              Text(album.selectedAt, format: Date.FormatStyle.abbreviated)
            }
          } label: {
            Text("Recognized")
          }
        }
      }
      .labeledContentStyle(.withThemeFont(.firstTextBaseline))
    }
  }
}

extension Date.FormatStyle {
  fileprivate static var abbreviated: Self {
    Self(date: .abbreviated, time: .shortened)
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
          AlbumLocationSection(location: location)
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
        .labeledContentStyle(.withThemeFont)
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
        .stopPlayerOnUrl()
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

private struct TestAlbumDetailView: View {
  @Environment(\.recordStoreLocator) private var locator

  @Query(sort: \Album.selectedAt, order: .reverse) private var albums: [Album]

  var body: some View {
    if let album = albums.first {
      AlbumDetailView(album: album)
        .task {
          guard
            let location = album.location,
            let stores = try? await locator.locate(
              near: location,
              within: .meters(500),
              limit: 3,
            )
          else { return }

          for store in stores {
            print(store.name)
            print(store.distance(from: location))
            print(store.address ?? "")
            print()
          }
        }
    } else {
      ProgressView()
    }
  }
}

#Preview(traits: .withSearchContext) {
  TestAlbumDetailView()
    .environment(\.recordStoreLocator, .live)
}
#endif
