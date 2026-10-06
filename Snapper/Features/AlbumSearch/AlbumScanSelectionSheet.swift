import SwiftUI

struct AlbumScanSelectionSheet: View {
  let model: AlbumScanFlowModel

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    if let entry = model.selectedEntry {
      AlbumCreation(
        entry: entry,
        onSave: model.markSaved,
        onShowAllResults: model.showAllResults,
      )
      .id(entry.id)
    } else {
      NavigationStack {
        List(model.results, id: \.id) { candidate in
          Button {
            model.select(candidate)
          } label: {
            AlbumCandidateRow(candidate: candidate)
          }
          .buttonStyle(.plain)
        }
        .navigationTitle("Scan results")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", role: .cancel) {
              dismiss()
            }
          }
        }
      }
    }
  }
}
