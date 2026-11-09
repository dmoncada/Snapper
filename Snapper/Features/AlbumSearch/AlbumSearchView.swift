import SwiftData
import SwiftUI

struct HomeView: View {
  @AppStorage(.storageKeys.openFirstResult)
  private var openFirstResult = true

  @Environment(\.locale) private var locale

  @Environment(AlbumSearchViewModel.self) private var vm

  @State private var searchText = ""
  @State private var selectedAlbum: Album?
  @State private var isCameraPresented = false
  @State private var isSettingsPresented = false

  @FocusState private var isFocused: Bool

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 0) {
        VStack(spacing: Spacing.sm) {
          HStack(spacing: Spacing.sm) {
            PhotoPickerButton("Pick", onData: onData) { _ in }

            Button("Snap", systemImage: "camera") {
              isCameraPresented = true
            }
            .buttonStyle(.theme)
          }

          TextField(text: $searchText) {
            Text("Or search by artist, album")
              .foregroundStyle(.themePlaceholder)
          }
          .autocorrectionDisabled(true)
          .keyboardType(.webSearch)
          .focused($isFocused)
          .accessibilityIdentifier("album-search-field")
          .textFieldStyle(
            .searchField(
              text: $searchText,
              isFocused: isFocused,
            )
          )
        }
        .padding(Padding.xl)

        AlbumCandidateSection(vm: vm) { candidate in
          selectedAlbum = candidate
        }
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
      )
      .fullScreenCover(isPresented: $isCameraPresented) {
        if openFirstResult {
          CameraAlbumScanScreen { data in
            isCameraPresented = false
            onData(data)
          }
        } else {
          CameraScanScreen(
            onBarcode: { barcode in
              isCameraPresented = false
              onBarcode(barcode)
            },
            onPhoto: { data in
              isCameraPresented = false
              onData(data)
            },
          )
        }
      }
      .toolbar {
        ToolbarTitle("MusicSnap")
        ToolbarItem(placement: .topBarTrailing) {
          Button("Settings", systemImage: "gearshape") {
            isSettingsPresented = true
            dismissKeyboard()
          }
        }
      }
      .withFullBackground()
      .dismissKeyboardOnTap()
    }
    .task(id: searchText) {
      await vm.search(by: .term(searchText), locale: locale)
    }
    .sheet(isPresented: $isSettingsPresented) {
      SettingsSheet()
        .presentationDetents([
          .medium
        ])
    }
    .sheet(item: $selectedAlbum) { album in
      AlbumCreation(album: album)
        .presentationDetents([
          .large
        ])
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
                    .contentShape(.rect)
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
#Preview("Default", traits: .withSearchContext) {
  HomeView()
}
#Preview("Loading", traits: .withSearchContext(kind: .slow)) {
  HomeView()
}
#Preview("Failure", traits: .withSearchContext(kind: .fail)) {
  HomeView()
}
#Preview("No items", traits: .withSearchContext(kind: .stub(0))) {
  HomeView()
}
#Preview("With items", traits: .withSearchContext(kind: .stub(3))) {
  HomeView()
}
#endif
