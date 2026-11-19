import Foundation

extension Collection {
  func sorted(
    by resource: KeyPath<Element, LocalizedStringResource>,
    locale: Locale = .current,
    order: Foundation.SortOrder = .forward,
  ) -> [Element] {
    map { element in
      var lookup = element[keyPath: resource]
      lookup.locale = locale
      return (
        element: element,
        label: String(localized: lookup),
      )
    }
    .sorted { lhs, rhs in
      let comparison = lhs.label.compare(
        rhs.label,
        options: .caseInsensitive,
        locale: locale,
      )

      let direction: ComparisonResult =
        order == .forward
        ? .orderedAscending
        : .orderedDescending

      return comparison == direction
    }
    .map { $0.element }
  }
}

extension Collection where Element == LocalizedStringResource {
  func sorted(
    locale: Locale = .current,
    order: Foundation.SortOrder = .forward,
  ) -> [Element] {
    sorted(by: \.self, locale: locale, order: order)
  }
}
