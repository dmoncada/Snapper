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
      VStack(alignment: .leading, spacing: Spacing.sm) {

        SearchField(
          text: $vm.searchText,
          placeholder: "Artist, album, barcode, etc...")

        HStack(spacing: Spacing.sm) {
          LargeButton("Pick") {}
            .frame(width: 100)

          LargeButton("Snap!") {}
        }

        AlbumCandidateSection(vm: vm, action: onSelect)
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
      )
      .padding()
      .toolbar {
        ToolbarTitle("MusicSnap")
        ToolbarItem(placement: .topBarTrailing) {
          Button("Settings", systemImage: "gearshape") {
            router.sheetItem = .settings
          }
        }
      }
      .navigationDestination(for: AlbumEntry.self) { destination in
        AlbumDetailView2(entry: destination)
      }
      .fullBackground(.themePrimary)
    }
    .onAppear {
      vm.locator = locator  // Inject locator.
    }
    .task(id: vm.searchText) {
      await vm.search()
    }
  }

  private func onSelect(selected: AlbumCandidate) {
    let entry = AlbumEntry(candidate: selected)
    entry.latitude = vm.location?.coordinate.latitude
    entry.longitude = vm.location?.coordinate.longitude
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
        }
        .scrollBounceBehavior(
          .basedOnSize,
          axes: .vertical
        )

      case .searching:
        ProgressView()
          .scaleEffect(2)
          .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
          )

      default:
        EmptyView()
      }

    } header: {
      let prefix = vm.results.isEmpty ? "No" : "All"

      Text("\(prefix) Candidates")
        .font(.libreCaslonTextBold(.headline))
        .padding(.vertical)
    }
  }
}

#Preview {
  @Previewable @State var locator = LocationManager()
  @Previewable @State var router = Router()

  HomeView()
    .withSheetDestination($router.sheetItem)
    .modelContainer(for: AlbumEntry.self)
    .environment(locator)
    .environment(router)
}
