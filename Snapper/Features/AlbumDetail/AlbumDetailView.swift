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
  @Environment(\.locale) private var locale

  init(genres: [Genre]) {
    self.genres = genres.compactMap { AlbumGenre(rawValue: $0.name) }
  }

  private let genres: [AlbumGenre]

  var body: some View {
    FlowLayout(alignment: .leading, spacing: Spacing.xs) {
      ForEach(genres.sorted(by: \.resource, locale: locale)) { genre in
        Text(genre.resource)
          .badgeStyle()
          .controlSize(.small)
      }
    }
  }
}

private struct AlbumDetailSection: View {
  @Environment(\.locale) private var locale

  let album: Album
  let showMetadata: Bool

  var body: some View {
    ThemeSection {
      Section(.detailSectionsAboutHeader) {
        if let label = album.label.first {
          LabeledContent(.detailLabelsLabel, value: label)
        }

        if let year = album.year?.description {
          LabeledContent(.detailLabelsReleased, value: year)
        }

        if let countryCode = album.countryCode, let countryName = album.countryName {
          let country = locale.localizedString(forRegionCode: countryCode)
          LabeledContent(.detailLabelsCountry, value: country ?? countryName)
        }

        if showMetadata {
          LabeledContent {
            VStack(alignment: .trailing, spacing: Spacing.xs) {
              TimelineView(.everyMinute) { _ in
                Text(album.selectedAt, format: .relative(presentation: .numeric))
              }
              Text(album.selectedAt, format: Date.FormatStyle.abbreviated)
            }
          } label: {
            Text(.detailLabelsRecognized)
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
          Text(.detailSectionsTracksHeader)
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
      Text(.detailSectionsTracksFooter)

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
import SwiftUI

private struct TestAlbumDetailView: View {
  @Environment(\.apiClient) private var apiClient

  @Query(sort: \Album.selectedAt, order: .reverse)
  private var albums: [Album]

  @State private var selectedIndex = 0

  private var selectedAlbum: Album? {
    if albums.isEmpty { return nil }
    return albums[selectedIndex % albums.count]
  }

  var body: some View {
    Group {
      if let album = selectedAlbum {
        AlbumDetailView(album: album)
          .id(album.persistentModelID)
          .task(id: album.persistentModelID) {
            await fetchInfo(for: album)
          }
      } else {
        ProgressView()
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button("Prev", systemImage: "chevron.left", action: selectPrev)
          .disabled(albums.count < 2)
      }

      ToolbarItem(placement: .principal) {
        Text("Album \(selectedIndex + 1) of \(albums.count)")
      }

      ToolbarItem(placement: .topBarTrailing) {
        Button("Next", systemImage: "chevron.right", action: selectNext)
          .disabled(albums.count < 2)
      }
    }
  }

  private func selectPrev() {
    if albums.isEmpty { return }
    selectedIndex = (selectedIndex - 1 + albums.count) % albums.count
  }

  private func selectNext() {
    if albums.isEmpty { return }
    selectedIndex = (selectedIndex + 1) % albums.count
  }

  private func fetchInfo(for album: Album) async {
    guard
      album.artistInfo.hasInfo == false,
      let response = try? await apiClient.fetchAlbumSummary(discogsId: album.discogsId)
    else { return }

    if let artistInfo = response.artist {
      album.artistInfo.set(artistInfo)
    }
    if let albumInfo = response.album {
      album.albumInfo.set(albumInfo)
    }
  }
}

#Preview(traits: .withSearchContext) {
  NavigationStack {
    TestAlbumDetailView()
      .environment(\.apiClient, .live)
      .environment(\.recordStoreLocator, .live)
  }
}
#endif
