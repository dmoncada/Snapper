import AVFoundation
import SwiftUI

struct ContentView: View {
  @State private var viewModel = AlbumSearchViewModel()
  @State private var playback = PreviewPlaybackController()

  var body: some View {
    @Bindable var viewModel = viewModel

    NavigationStack {
      List {
        Section {
          Picker("Search input", selection: $viewModel.searchMode) {
            Text("Term").tag(AlbumSearchMode.term)
            Text("Barcode").tag(AlbumSearchMode.barcode)
          }
          .pickerStyle(.segmented)

          TextField(
            viewModel.searchMode == .term ? "Artist or album" : "UPC or EAN",
            text: $viewModel.query
          )
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
        }

        Section("Album Candidates") {
          switch viewModel.searchState {
          case .idle:
            ContentUnavailableView(
              "Start Searching",
              systemImage: "magnifyingglass",
              description: Text("Enter an artist, album, or barcode."))

          case .searching:
            HStack {
              ProgressView()
              Text("Searching Discogs...")
            }

          case .empty:
            ContentUnavailableView(
              "No Matches",
              systemImage: "music.note.list",
              description: Text("Try a different search."))

          case .error(let message):
            ContentUnavailableView(
              "Unable to Search",
              systemImage: "exclamationmark.triangle",
              description: Text(message))

          case .results:
            ForEach(viewModel.candidates) { candidate in
              NavigationLink(value: viewModel.selection(for: candidate)) {
                AlbumCandidateRow(candidate: candidate)
              }
            }
          }
        }
      }
      .navigationTitle("Snap")
      .navigationDestination(for: AlbumSelection.self) { selection in
        AlbumDetailView(selection: selection, playback: playback)
      }
    }
    .safeAreaInset(edge: .bottom) {
      PreviewMiniPlayer(playback: playback)
    }
    .task(id: [viewModel.searchMode.rawValue, viewModel.query]) {
      await viewModel.search()
    }
    .task(id: playback.itemIdentifier) {
      await playback.observeItemEnd()
    }
    .task(id: playback.itemIdentifier) {
      await playback.observeItemFailure()
    }
    .onChange(of: playback.player?.currentItem?.status) { _, status in
      playback.handleItemStatus(status)
    }
    .onChange(of: playback.player?.timeControlStatus) {
      playback.updateNowPlaying()
    }
    .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) {
      _ in
      playback.pause()
    }
  }
}

#Preview {
  ContentView()
}
