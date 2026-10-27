import SwiftData
import SwiftUI

struct HomeView: View {
  @AppStorage(.storageKeys.openFirstResult)
  private var openFirstResult = true

  @Environment(\.locale) private var locale

  @Environment(AlbumSearchViewModel.self) private var vm
  @Environment(Router.self) private var router

  @State private var searchText = ""
  @State private var isPresented = false

  @FocusState private var isFocused: Bool

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 0) {
        VStack(spacing: Spacing.sm) {
          HStack(spacing: Spacing.sm) {
            PhotoPickerButton("Pick", onData: onData) { _ in }
              .frame(width: 100)

            Button("Snap") { isPresented = true }
              .buttonStyle(.large)
          }

          /*
          SearchField(text: $searchText, placeholder: "Or search by artist, album")
            .keyboardType(.webSearch)
           */

          TextField(text: $searchText) {
            Text("Or search by artist, album")
          }
          .autocorrectionDisabled(true)
          .keyboardType(.webSearch)
          .focused($isFocused)
          .textFieldStyle(
            .searchField(
              text: $searchText,
              isFocused: isFocused,
            )
          )
        }
        .padding(Padding.xl)

        AlbumCandidateSection(vm: vm) { candidate in
          router.sheetItem = .create(candidate)
        }
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
      )
      .fullScreenCover(isPresented: $isPresented) {
        if openFirstResult {
          CameraAlbumScanScreen { data in
            isPresented = false
            onData(data)
          }
        } else {
          CameraScanScreen(
            onBarcode: { barcode in
              isPresented = false
              onBarcode(barcode)
            },
            onPhoto: { data in
              isPresented = false
              onData(data)
            },
          )
        }
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
    .task(id: searchText) {
      await vm.search(by: .term(searchText), locale: locale)
    }
  }

  private func onBarcode(_ barcode: String) {
    Task {
      await vm.search(by: .barcode(barcode), locale: locale)
    }
  }

  private func onData(_ data: Data) {
    Task {
      await vm.detect(in: data, locale: locale)
    }
  }
}

private struct AlbumCandidateSection: View {
  let vm: AlbumSearchViewModel
  let action: (Album) -> Void

  var body: some View {
    VStack {
      switch vm.state {
      case .ready:
        Text("Ready to search")

      case .searching:
        ProgressView("Searching term...")

      case .detecting:
        ProgressView("Detecting barcode...")

      case .cancelled:
        Text("Search cancelled")

      case .failure(let error):
        ContentUnavailableView(error.localizedDescription, systemImage: "xmark.circle")

      case .success(let albums) where albums.isEmpty:
        ContentUnavailableView.search

      case .success(let albums):
        ScrollView {
          ThemeSection {
            Section {
              ForEach(albums) { candidate in
                Button {
                  action(candidate)
                } label: {
                  AlbumCandidateRow(album: candidate)
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(.horizontal, Padding.xl)
        }
        .scrollDismissesKeyboard(.immediately)
      }
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
    )
  }
}

#if DEBUG
#Preview("Default", traits: .withoutData) {
  @Previewable @State var router = Router()

  HomeView()
    .withSheetDestination($router.sheetItem)
    .environment(
      AlbumSearchViewModel(
        apiClient: .live,
        recognizer: .stub(result: .barcode("843563174807")),
      )
    )
    .environment(AlbumLocationCaptureCoordinator(locator: .stub(.newYork)))
    .environment(\.previewPlayer, .live)
    .environment(router)
}

#Preview("In tab", traits: .withoutData) {
  @Previewable @State var router = Router()

  TabView {
    Tab {
      HomeView()
    }
  }
  .withSheetDestination($router.sheetItem)
  .environment(
    AlbumSearchViewModel(
      apiClient: .live,
      recognizer: .stub(result: .barcode("843563174807")),
    )
  )
  .environment(AlbumLocationCaptureCoordinator(locator: .stub(.newYork)))
  .environment(\.previewPlayer, .live)
  .environment(router)
}
#endif
