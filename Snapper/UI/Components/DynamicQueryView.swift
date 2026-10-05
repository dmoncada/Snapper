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
