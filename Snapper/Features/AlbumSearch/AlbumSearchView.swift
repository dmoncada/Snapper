import CoreLocation
import SwiftData
import SwiftUI

struct HomeView: View {
  @Environment(\.modelContext) private var context
  @Environment(Router.self) private var router

  @State private var vm = AlbumSearchViewModel()
  @State private var path: [AlbumEntry] = []
  @State private var isPresented = false

  var body: some View {
    NavigationStack(path: $path) {
      VStack(alignment: .leading, spacing: 0) {
        VStack(spacing: Spacing.sm) {
          HStack(spacing: Spacing.sm) {
            PhotoPickerButton("Pick", onData: onData) { _ in }
              .frame(width: 100)

            Button("Snap") { isPresented = true }
              .buttonStyle(.large)
          }

          SearchField(text: $vm.searchText, placeholder: "Or search by artist, album")
            .keyboardType(.webSearch)
        }
        .padding(Padding.xl)

        AlbumCandidateSection(vm: vm) { candidate in
          let entry = AlbumEntry(candidate: candidate)
          router.sheetItem = .create(entry)
        }
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
      )
      .fullScreenCover(isPresented: $isPresented) {
        CameraScanScreen(
          onBarcode: { barcode in
            isPresented = false
            vm.searchText = barcode
          },
          onPhoto: { data in
            isPresented = false
            onData(data: data)
          },
        )
        .presentationDetents([.large])
      }
      .toolbar {
        ToolbarTitle("MusicSnap")
        ToolbarItem(placement: .topBarTrailing) {
          Button("Settings", systemImage: "gearshape") {
            router.sheetItem = .settings
            dismissKeyboard()
          }
        }
      }
      .fullBackground(.themePrimary)
      .dismissKeyboardOnTap()
    }
    .task(id: vm.searchText) {
      await vm.search()
    }
  }

  private func onData(data: Data) {
    Task {
      do {
        try await vm.recognize(in: data)
      } catch {
        print(error.localizedDescription)
      }
    }
  }
}

private struct AlbumCandidateSection: View {
  let vm: AlbumSearchViewModel
  let action: (AlbumCandidate) -> Void

  var body: some View {
    Section {
      switch vm.state {
      case .idle:
        ContentUnavailableView.search

      case .searching, .recognizing:
        ProgressView(vm.state.description).frame(maxWidth: .infinity, maxHeight: .infinity)

      case .unreadable:
        ContentUnavailableView("Unreadable", systemImage: "xmark.circle")

      case .error(let error):
        ContentUnavailableView(error, systemImage: "xmark.circle")

      case .results:
        ScrollView(.vertical) {
          VStack {
            ForEach(vm.results.enumerated(), id: \.offset) { i, candidate in
              Button {
                action(candidate)
              } label: {
                VStack {
                  AlbumCandidateRow(candidate: candidate)
                  if i < vm.results.count - 1 {
                    Divider()
                  }
                }
              }
              .buttonStyle(.plain)
            }
          }
          .padding(Padding.xl)
        }
        .scrollDismissesKeyboard(.interactively)

      default:
        EmptyView()
      }
    }
  }
}

#if DEBUG
#Preview("Default") {
  @Previewable @State var router = Router()

  HomeView()
    .withSheetDestination($router.sheetItem)
    .modelContainer(for: AlbumEntry.self)
    .environment(AlbumLocationCaptureCoordinator())
    .environment(PreviewPlayer())
    .environment(router)
}

#Preview("In tab") {
  @Previewable @State var router = Router()

  TabView {
    Tab {
      HomeView()
    }
  }
  .withSheetDestination($router.sheetItem)
  .modelContainer(for: AlbumEntry.self)
  .environment(AlbumLocationCaptureCoordinator())
  .environment(PreviewPlayer())
  .environment(router)
}
#endif
