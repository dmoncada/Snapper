#if DEBUG
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SampleDataExportView: View {
  @Environment(\.modelContext) private var context

  @State private var isExporting = false
  @State private var isImporting = false

  @State private var exportDocument: JsonDocument?
  @State private var alertItem: AlertDestination?

  private var albumCount: Int {
    context.getCount(for: Album.self)
  }

  private var trackCount: Int {
    context.getCount(for: Track.self)
  }

  var body: some View {
    List {
      Section("Model counts") {
        LabeledContent("Album count", value: String(albumCount))
        LabeledContent("Track count", value: String(trackCount))
      }

      Section {
        Button("Import Json fixture", systemImage: "square.and.arrow.down") {
          isImporting = true
        }

        Button("Export albums and tracks", systemImage: "square.and.arrow.up") {
          exportJson()
        }
      } header: {
        Text("Json Fixtures")
      } footer: {
        Text("Export saves all albums and their tracks as a reusable Json fixture.")
          .foregroundStyle(.secondary)
          .font(.footnote)
      }
    }
    .navigationTitle("Sample Data")
    .fileImporter(
      isPresented: $isImporting,
      allowedContentTypes: [.json],
      allowsMultipleSelection: false,
    ) { result in
      importJson(result)
    }
    .fileExporter(
      isPresented: $isExporting,
      document: exportDocument,
      contentType: .json,
      defaultFilename: "albums",
      onCompletion: { result in
        switch result {
        case .success:
          alertItem = .ok("Fixture exported successfully.", title: "Success!")

        case .failure(let error):
          alertItem = .ok(LocalizedStringResource(error: error))
        }
      },
    )
    .withAlertDestination($alertItem)
  }

  @MainActor
  private func exportJson() {
    isExporting = true

    do {
      let data = try SampleDataLoader.exportData(from: context)
      exportDocument = JsonDocument(data: data)
    } catch {
      alertItem = .ok(LocalizedStringResource(error: error))
    }
  }

  @MainActor
  private func importJson(_ result: Result<[URL], Error>) {
    do {
      guard let url = try result.get().first else {
        return
      }

      let accessed = url.startAccessingSecurityScopedResource()
      defer {
        if accessed {
          url.stopAccessingSecurityScopedResource()
        }
      }

      let file = try SampleDataLoader.decode(Data(contentsOf: url))

      try SampleDataLoader.insert(
        file,
        into: context,
        replacingExisting: true,
      )

      alertItem = .ok("Imported \(file.albums.count) albums.", title: "Success!")
    } catch {
      alertItem = .ok(LocalizedStringResource(error: error))
    }
  }
}

extension LocalizedStringResource {
  fileprivate init(error: Error) {
    self.init(stringLiteral: error.localizedDescription)
  }
}

#Preview(traits: .withSampleData) {
  SampleDataExportView()
}
#endif
