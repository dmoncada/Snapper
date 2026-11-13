import Foundation

extension Date {
  func subtracting(
    _ value: Int,
    unit: Calendar.Component,
  ) -> Date {
    Calendar.current.date(
      byAdding: unit,
      value: -value,
      to: self,
    ) ?? self
  }
}
