import SwiftData
import SwiftUI

struct AlbumSearchView: View {
  @AppStorage(.storageKeys.colorScheme)
  private var preference: ColorSchemePreference = .system

  @AppStorage(.storageKeys.openFirstResult)
  private var openFirstResult = true

  @Environment(\.locale) private var locale
  @Environment(\.colorScheme) private var systemScheme

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
            PhotoPickerButton(.Search.buttonsPick, onData: onData) { _ in }

            Button(.Search.buttonsSnap, systemImage: "camera") {
              isCameraPresented = true
            }
            .buttonStyle(.theme)
          }

          TextField(text: $searchText) {
            Text(.Search.textfieldPlaceholder)
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
      .navigationTitle(.Search.title)
      .navigationSubtitle(.Search.stateReady)
      .toolbar {
        // ToolbarTitle(.Search.title)
        ToolbarItem(placement: .topBarTrailing) {
          Button(.Settings.title, systemImage: "gearshape") {
            isSettingsPresented = true
            dismissKeyboard()
          }
        }
      }
      .task(id: searchText) {
        await vm.search(by: .term(searchText), locale: locale)
      }
      .sheet(isPresented: $isSettingsPresented) {
        SettingsSheet()
          .preferredColorScheme(preference.colorScheme ?? systemScheme)
          .presentationDetents([
            .fraction(3 / 4)
          ])
      }
      .sheet(item: $selectedAlbum) { album in
        AlbumCreation(album: album)
          .presentationDetents([
            .large
          ])
      }
      .withFullBackground()
      .dismissKeyboardOnTap()
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
        Text(.Search.stateReady)

      case .searching:
        ProgressView(.Search.stateSearching)

      case .detecting:
        ProgressView(.Search.stateDetecting)

      case .cancelled:
        Text(.Search.stateCancelled)

      case .failure(let error):
        AlbumSearchErrorView(error: error)

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

private struct AlbumSearchErrorView: View {
  let error: AlbumSearchError

  var body: some View {
    ContentUnavailableView {
      Label(.searchErrorLabel, systemImage: "xmark.circle")
    } description: {
      Text(error.resource)
    }
  }
}

#if DEBUG
extension AlbumSearchView {
  fileprivate init(searching searchText: String) {
    _searchText = State(initialValue: searchText)
  }
}

#Preview("Default", traits: .withSearchContext) {
  AlbumSearchView()
}
#Preview("Loading", traits: .withSearchContext(kind: .slow)) {
  AlbumSearchView(searching: "slow")
}
#Preview("Failure", traits: .withSearchContext(kind: .fail)) {
  AlbumSearchView(searching: "fail")
}
#Preview("No items", traits: .withSearchContext(kind: .stub(count: 0))) {
  AlbumSearchView(searching: "stub(0)")
}
#Preview("With items", traits: .withSearchContext(kind: .stub(count: 3))) {
  AlbumSearchView(searching: "stub(3)")
}
#endif
