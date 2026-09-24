import SwiftData
import SwiftUI

struct RecognitionView: View {
  let playback: PreviewPlaybackController

  @Environment(\.modelContext) private var modelContext
  @State private var viewModel = AlbumSearchViewModel()
  @State private var path: [AlbumDetailRoute] = []
  @State private var historySaveError: String?
  @State private var locationCaptureService = AlbumLocationCaptureService()
  @State private var imageDataToRecognize: Data?
  @State private var imageRecognitionID = UUID()

  var body: some View {
    @Bindable var viewModel = viewModel

    NavigationStack(path: $path) {
      List {
        AlbumImageSourceSection(
          onImage: scheduleImageRecognition,
          onError: viewModel.reportImageImportError,
          isDisabled: viewModel.isScanningImage)

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
        .disabled(viewModel.isScanningImage)

        Section("Album Candidates") {
          switch viewModel.searchState {
          case .idle:
            ContentUnavailableView(
              "Start Searching",
              systemImage: "magnifyingglass",
              description: Text("Enter an artist, album, or barcode."))

          case .recognizing:
            HStack {
              ProgressView()
              Text("Reading image...")
            }

          case .searching:
            HStack {
              ProgressView()
              Text("Searching Discogs...")
            }

          case .empty:
            ContentUnavailableView(
              "No Matches",
              systemImage: "music.note.list",
              description: Text("Try another query or scan a different side."))

          case .unreadable:
            ContentUnavailableView(
              "Couldn’t Read Album",
              systemImage: "text.viewfinder",
              description: Text(
                "No barcode or clear album text was found. Try another side or search manually."))

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
      .navigationDestination(for: AlbumDetailRoute.self) { route in
        AlbumDetailView(
          selection: route.selection,
          historyEntryID: route.historyEntryID,
          playback: playback)
      }
    }
    .task(id: [viewModel.searchMode.rawValue, viewModel.query]) {
      await viewModel.search()
    }
    .task(id: imageRecognitionID) {
      guard let imageDataToRecognize else { return }
      await viewModel.recognizeAndSearch(imageData: imageDataToRecognize)
      self.imageDataToRecognize = nil
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

  private func scheduleImageRecognition(_ imageData: Data) {
    imageDataToRecognize = imageData
    imageRecognitionID = UUID()
  }

  private func open(_ candidate: AlbumCandidate) {
    let selection = viewModel.selection(for: candidate)
    let entry = AlbumHistoryEntry(selection: selection)
    modelContext.insert(entry)

    do {
      try modelContext.save()
      path.append(AlbumDetailRoute(selection: selection, historyEntryID: entry.id))
      captureLocation(for: entry.id)

    } catch {
      modelContext.delete(entry)
      historySaveError = error.localizedDescription
      path.append(AlbumDetailRoute(selection: selection, historyEntryID: entry.id))
    }
  }

  private func captureLocation(for entryID: UUID) {
    Task {
      guard let location = await locationCaptureService.captureCurrentLocation() else { return }

      let descriptor = FetchDescriptor<AlbumHistoryEntry>(
        predicate: #Predicate { $0.id == entryID })

      guard let entry = try? modelContext.fetch(descriptor).first else { return }

      entry.latitude = location.latitude
      entry.longitude = location.longitude
      entry.horizontalAccuracy = location.horizontalAccuracy
      entry.locationCapturedAt = location.capturedAt
      entry.locationLabel = location.placeLabel

      do {
        try modelContext.save()

      } catch {
        historySaveError = error.localizedDescription
      }
    }
  }
}
