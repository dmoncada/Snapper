import SwiftData
import SwiftUI

struct HomeView: View {
  @Environment(\.modelContext) var context

  @Environment(LocationManager.self) var locator
  @Environment(Router.self) var router

  @State private var vm = AlbumSearchViewModel2()
  @State private var path: [AlbumEntry] = []

  var body: some View {
    NavigationStack(path: $path) {
      VStack(alignment: .leading, spacing: 0) {
        VStack(spacing: Spacing.md) {
          SearchField(text: $vm.searchText, placeholder: "Artist, album, barcode")
            .keyboardType(.webSearch)

          HStack(spacing: Spacing.sm) {
            LargeButton("Pick") {}
              .frame(width: 100)

            LargeButton("Snap!") {}
          }
        }
        .padding(Padding.xl)

        AlbumCandidateSection(vm: vm) { candidate in
          createEntry(candidate, location: nil)
        }
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
      )
      .toolbarBackground(.thinMaterial, for: .navigationBar)
      .toolbarBackgroundVisibility(.visible, for: .navigationBar)
      .toolbar {
        ToolbarTitle("MusicSnap")
        ToolbarItem(placement: .topBarTrailing) {
          Button("Settings", systemImage: "gearshape") {
            router.sheetItem = .settings
            dismissKeyboard()
          }
        }
      }
      .navigationDestination(for: AlbumEntry.self) { destination in
        AlbumDetailView2(entry: destination)
      }
      .fullBackground(.themePrimary)
      .dismissKeyboardOnTap()
    }
    .task(id: vm.searchText) {
      await vm.search()
    }
  }

  private func createEntry(_ candidate: AlbumCandidate, location: CLLocation?) {
    let entry = AlbumEntry(candidate: candidate)
    entry.latitude = location?.coordinate.latitude
    entry.longitude = location?.coordinate.longitude
    path.append(entry)

    context.insert(entry)
    if context.hasChanges {
      try? context.save()
    }
  }
}

private struct AlbumCandidateSection: View {
  let vm: AlbumSearchViewModel2
  let action: (AlbumCandidate) -> Void

  var body: some View {
    Section {
      switch vm.state {
      case .idle:
        ContentUnavailableView {
          Text("Snap away!")
            .font(.libreCaslonTextBold(.headline))

        } description: {
          Text("Search artists, albums and more...")
            .font(.libreCaslonTextRegular(.subheadline))
        }

      case .searching:
        ProgressView()
          .scaleEffect(2)
          .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
          )

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

      case .error(let error):
        ContentUnavailableView {
          Text("Oh no!")
            .font(.libreCaslonTextBold(.headline))

        } description: {
          Text(error)
            .font(.libreCaslonTextRegular(.subheadline))
        }

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
      .environment(LocationManager())
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
    .environment(LocationManager())
    .environment(PreviewPlayer())
    .environment(router)
  }
#endif
