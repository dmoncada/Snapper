import SwiftData
import SwiftUI

struct AlbumSearchView: View {
  @AppStorage(.storageKeys.colorScheme)
  private var preference: ColorSchemePreference = .system

  @AppStorage(.storageKeys.openFirstResult)
  private var openFirstResult = true

  @Environment(\.locale) private var locale
  @Environment(\.navigation) private var navigation
  @Environment(\.colorScheme) private var systemScheme

  @Environment(AlbumSearchViewModel.self) private var vm

  @State private var isMounted = false
  @State private var selectedAlbum: Album?
  @State private var isCameraPresented = false
  @State private var isSettingsPresented = false

  @FocusState private var isFocused: Bool

  var body: some View {
    @Bindable var vm = vm

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

          TextField(text: $vm.searchText) {
            Text(.Search.textfieldPlaceholder)
              .foregroundStyle(.themePlaceholder)
          }
          .autocorrectionDisabled(true)
          .keyboardType(.webSearch)
          .focused($isFocused)
          .accessibilityIdentifier("album-search-field")
          .textFieldStyle(
            .searchField(
              text: $vm.searchText,
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
      .task(id: vm.searchText) {
        defer { isMounted = true }
        guard isMounted else { return }
        await vm.search(by: .term(vm.searchText), locale: locale)
      }
      .sheet(isPresented: $isSettingsPresented) {
        SettingsSheet()
          .preferredColorScheme(preference.colorScheme ?? systemScheme)
          .presentationDetents([.fraction(3 / 4)])
      }
      .sheet(item: $selectedAlbum) { album in
        AlbumCreation(album: album)
          .presentationDetents([.large])
      }
      .withFullBackground()
      .dismissKeyboardOnTap()
    }
    .onChange(of: canPresentCameraFromDeepLink, initial: true) { _, canPresentCamera in
      guard canPresentCamera, let navigation else { return }
      navigation.deepLink = nil
      isCameraPresented = true
    }
  }

  private var canPresentCameraFromDeepLink: Bool {
    true
      && navigation?.screen == .search
      && navigation?.deepLink == .camera
      && isSettingsPresented == false
      && selectedAlbum == nil
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
          .secondary()

      case .searching:
        ProgressView(.Search.stateSearching)
          .secondary()

      case .detecting:
        ProgressView(.Search.stateDetecting)
          .secondary()

      case .cancelled:
        Text(.Search.stateCancelled)
          .secondary()

      case .failed(let error):
        ThemeContentUnavailableView.error(.searchErrorLabel, description: error.resource)

      case .loaded(let albums) where albums.isEmpty:
        ThemeContentUnavailableView.search(text: vm.searchText)

      case .loaded(let albums):
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
    .font(.gillSans(.title3))
    .foregroundStyle(.themePrimary)
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
    )
  }
}

extension View {
  fileprivate func secondary() -> some View {
    self
      .font(.gillSans(.title3))
      .foregroundStyle(.secondary)
  }
}

#if DEBUG
private struct TestAlbumSearchView: View {
  @Environment(AlbumSearchViewModel.self) private var vm

  let searching: String

  var body: some View {
    AlbumSearchView()
      .onAppear {
        vm.searchText = searching
      }
  }
}

#Preview("Default", traits: .withSearchContext) {
  AlbumSearchView()
}
#Preview("Loading", traits: .withSearchContext(kind: .slow)) {
  TestAlbumSearchView(searching: "slow")
}
#Preview("Failure", traits: .withSearchContext(kind: .fail)) {
  TestAlbumSearchView(searching: "fail")
}
#Preview("No items", traits: .withSearchContext(kind: .stub(count: 0))) {
  TestAlbumSearchView(searching: "stub(0)")
}
#Preview("With items", traits: .withSearchContext(kind: .stub(count: 3))) {
  TestAlbumSearchView(searching: "stub(3)")
}
#endif
