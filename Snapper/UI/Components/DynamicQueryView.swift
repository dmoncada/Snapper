import SwiftData
import SwiftUI

// Taken from: https://livsycode.com/swiftui/swiftdata-dynamic-query-and-fetchdescriptor/
struct DynamicQueryView<Element: PersistentModel, Content: View>: View {
  private let descriptor: FetchDescriptor<Element>
  private let content: ([Element]) -> Content

  @Query private var items: [Element]

  init(
    _ descriptor: FetchDescriptor<Element>,
    @ViewBuilder content: @escaping ([Element]) -> Content,
  ) {
    self.descriptor = descriptor
    self.content = content

    _items = Query(descriptor, animation: .easeInOut(duration: 0.25))
  }

  var body: some View {
    content(items)
  }
}

#if DEBUG
private struct TestDynamicQueryView: View {
  var descriptor: FetchDescriptor<Album> {
    let fetch = #Predicate<Album> { _ in true }
    let sort = SortDescriptor<Album>(\.artist, order: .forward)
    return FetchDescriptor(predicate: fetch, sortBy: [sort])
  }

  var body: some View {
    DynamicQueryView(descriptor) { items in
      let albums = Dictionary(grouping: items, by: \.artist)

      List {
        ForEach(albums.keys.sorted(), id: \.self) { artist in
          Section(artist) {
            ForEach(albums[artist] ?? []) { album in
              Text(album.title)
                .lineLimit(1)
            }
          }
        }
      }
    }
  }
}

#Preview(traits: .withSampleData) {
  TestDynamicQueryView()
}
#endif
