import SwiftUI

struct BadgeStyleModifier: ViewModifier {
  let isActive: Bool

  @Environment(\.controlSize) private var controlSize

  private var textStyle: Font.TextStyle {
    switch controlSize {
    case .mini: .caption2
    case .small: .caption
    case .regular: .body
    case .large: .title3
    case .extraLarge: .title2
    @unknown default: .body
    }
  }

  func body(content: Content) -> some View {
    content
      .padding(Padding.md)
      .font(.sligoilMicroBold(textStyle))
      .foregroundStyle(
        isActive
          ? .themePrimary
          : .themePrimaryInverted
      )
      .background {
        if isActive {
          RoundedRectangle(cornerRadius: Radius.md)
            .fill(.tint)
        } else {
          RoundedRectangle(cornerRadius: Radius.md)
            .stroke(.themePrimaryInverted, lineWidth: LineWidth.sm)
        }
      }
  }
}

struct BadgeToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      configuration.label
        .badgeStyle(isActive: configuration.isOn)
        .animation(nil, value: configuration.isOn)
    }
    .buttonStyle(.plain)
  }
}

extension View {
  func badgeStyle(isActive: Bool = false) -> some View {
    modifier(BadgeStyleModifier(isActive: isActive))
  }
}

extension ToggleStyle where Self == BadgeToggleStyle {
  static var badge: Self { Self() }
}

struct FilterBar: View {
  enum Filter: String, CaseIterable, Identifiable {
    case all, favorites, rock, pop

    var id: Self { self }

    var title: String { rawValue.capitalized }
  }

  @Binding var selectedFilter: Filter

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: Spacing.sm) {
        ForEach(Filter.allCases) { filter in
          Toggle(
            filter.title,
            isOn: Binding(
              get: { selectedFilter == filter },
              set: { if $0 { selectedFilter = filter } },
            ),
          )
          .toggleStyle(.badge)
        }
      }
      .padding(1)
    }
  }
}

#if DEBUG
private struct TestBadge: View {
  @State private var isOn1 = false
  @State private var isOn2 = false

  var body: some View {
    VStack {
      Text("Badge")
        .badgeStyle()
        .controlSize(.small)

      Toggle("Toggle", isOn: $isOn1)
        .toggleStyle(.badge)
        .controlSize(.regular)

      Toggle("Tinted toggle", isOn: $isOn2)
        .toggleStyle(.badge)
        .controlSize(.large)
        .tint(.blue)
    }
  }
}

private struct CompleteView: View {
  private struct Item: Identifiable {
    let id: Int
    let category: FilterBar.Filter

    var title: String {
      "Item \(id)"
    }
  }

  @State private var selectedFilter: FilterBar.Filter = .all

  private let items: [Item] = (1 ... 100)
    .map { index in
      let categories: [FilterBar.Filter] = [.favorites, .rock, .pop]

      return Item(
        id: index,
        category: categories[(index - 1) % categories.count],
      )
    }

  private var filteredItems: [Item] {
    if selectedFilter == .all {
      return items
    }

    return items.filter { $0.category == selectedFilter }
  }

  var body: some View {
    ScrollView(.vertical) {
      FilterBar(selectedFilter: $selectedFilter)

      LazyVStack(spacing: 0) {
        ForEach(filteredItems) { item in
          LabeledContent {
            Text(item.category.title)
              .font(.caption)
              .foregroundStyle(.secondary)
          } label: {
            Text(item.title)
          }
          .padding(.vertical)
          .tag(item.id)

          Divider()
        }
      }
    }
    .padding(.horizontal)
  }
}

#Preview("Filter Bar") {
  CompleteView()
}

#Preview("Component") {
  WithColorSchemes {
    TestBadge()
      .frame(maxWidth: .infinity)
      .padding()
  }
}
#endif
