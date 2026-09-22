import SwiftData
import SwiftUI

struct RecognitionView: View {
  let playback: PreviewPlaybackController

  @Environment(\.modelContext) private var modelContext
  @State private var viewModel = AlbumSearchViewModel()
  @State private var path: [AlbumSelection] = []
  @State private var historySaveError: String?

  var body: some View {
    @Bindable var viewModel = viewModel

    NavigationStack(path: $path) {
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
              Button {
                open(candidate)
              } label: {
                AlbumCandidateRow(candidate: candidate)
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
      .navigationTitle("Recog")
      .navigationDestination(for: AlbumSelection.self) { selection in
        AlbumDetailView(selection: selection, playback: playback)
      }
    }
    .task(id: [viewModel.searchMode.rawValue, viewModel.query]) {
      await viewModel.search()
    }
    .alert("Couldn’t Save to History", isPresented: historySaveErrorIsPresented) {
      Button("Continue", role: .cancel) {
        historySaveError = nil
      }
    } message: {
      Text(historySaveError ?? "The album will still open.")
    }
  }

  private var historySaveErrorIsPresented: Binding<Bool> {
    Binding(
      get: { historySaveError != nil },
      set: { if !$0 { historySaveError = nil } })
  }

  private func open(_ candidate: AlbumCandidate) {
    let selection = viewModel.selection(for: candidate)
    let entry = AlbumHistoryEntry(selection: selection)
    modelContext.insert(entry)

    do {
      try modelContext.save()
    } catch {
      modelContext.delete(entry)
      historySaveError = error.localizedDescription
    }

    path.append(selection)
  }
}
