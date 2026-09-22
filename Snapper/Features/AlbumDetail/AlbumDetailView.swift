import SwiftUI

struct AlbumDetailView: View {
  let selection: AlbumSelection
  let playback: PreviewPlaybackController

  @State private var viewModel: AlbumDetailViewModel

  init(selection: AlbumSelection, playback: PreviewPlaybackController) {
    self.selection = selection
    self.playback = playback
    _viewModel = State(initialValue: AlbumDetailViewModel(selection: selection))
  }

  var body: some View {
    List {
      Section {
        Text(selection.candidate.title)
          .bold()
        Text(selection.candidate.artist)
          .foregroundStyle(.secondary)
      }

      AlbumDetailContent(viewModel: viewModel, playback: playback)
    }
    .navigationTitle("Album")
    .task(id: viewModel.loadAttempt) {
      await viewModel.load()
    }
  }
}

private struct AlbumDetailContent: View {
  let viewModel: AlbumDetailViewModel
  let playback: PreviewPlaybackController

  var body: some View {
    switch viewModel.state {
    case .loading:
      Section {
        HStack {
          ProgressView()
          Text("Loading tracklist...")
        }
      }

    case .loaded:
      if let detail = viewModel.detail {
        Section("Tracks") {
          ForEach(detail.tracks) { track in
            AlbumTrackRow(
              track: track,
              artist: detail.artist,
              album: detail.title,
              playback: playback)
          }
        }

        Section {
          Text(detail.source.title)
            .font(.subheadline)
            .foregroundStyle(.secondary)

          if let discogsUrl = detail.discogsUrl {
            Link("View on Discogs", destination: discogsUrl)
          }

          if let itunesUrl = detail.source.itunesUrl {
            Link("View in iTunes", destination: itunesUrl)
          }
        }
      }

    case .error(let message):
      Section {
        ContentUnavailableView(
          "Unable to Load Tracklist",
          systemImage: "exclamationmark.triangle",
          description: Text(message))
        Button("Try Again") {
          viewModel.retry()
        }
      }
    }
  }
}
