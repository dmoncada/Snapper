import SwiftData
import SwiftUI

struct AlbumHistoryView: View {
  let playback: PreviewPlaybackController

  @Environment(\.modelContext) private var modelContext

  @Query(sort: \AlbumHistoryEntry.selectedAt, order: .reverse)
  private var entries: [AlbumHistoryEntry]

  @State private var isConfirmingClear = false
  @State private var saveError: String?

  var body: some View {
    NavigationStack {
      List {
        if entries.isEmpty {
          ContentUnavailableView(
            "No History Yet",
            systemImage: "clock.arrow.circlepath",
            description: Text("Albums you open from Recog will appear here."))

        } else {
          ForEach(entries) { entry in
            NavigationLink(
              value: AlbumDetailRoute(selection: entry.selection, historyEntryID: entry.id)
            ) {
              AlbumHistoryRow(entry: entry)
            }
            .swipeActions {
              Button(role: .destructive) {
                modelContext.delete(entry)
                saveChanges()
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
        }
      }
      .navigationTitle("History")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Clear History", systemImage: "trash") {
            isConfirmingClear = true
          }
          .disabled(entries.isEmpty)
        }
      }
      .confirmationDialog(
        "Clear all album history?",
        isPresented: $isConfirmingClear,
        titleVisibility: .visible
      ) {
        Button("Clear History", role: .destructive) {
          for entry in entries {
            modelContext.delete(entry)
          }
          saveChanges()
        }
      } message: {
        Text("This removes every saved album selection.")
      }
      .navigationDestination(for: AlbumDetailRoute.self) { route in
        AlbumDetailView(
          selection: route.selection,
          historyEntryID: route.historyEntryID,
          playback: playback)
      }
      .alert("Couldn’t Save History", isPresented: saveErrorIsPresented) {
        Button("OK", role: .cancel) {
          saveError = nil
        }
      } message: {
        Text(saveError ?? "Try again.")
      }
    }
  }

  private var saveErrorIsPresented: Binding<Bool> {
    Binding(
      get: { saveError != nil },
      set: { if !$0 { saveError = nil } })
  }

  private func saveChanges() {
    do {
      try modelContext.save()
    } catch {
      saveError = error.localizedDescription
    }
  }
}
