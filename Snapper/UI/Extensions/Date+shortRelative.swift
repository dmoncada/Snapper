import Foundation

/*
extension Date {
  func shortRelative(to now: Date = .now) -> String {
    let seconds = max(0, now.timeIntervalSince(self))

    let minute = 60.0
    let hour = 60.0 * minute
    let day = 24.0 * hour
    let week = 7.0 * day
    let month = 30.0 * day
    let year = 365.0 * day

    switch seconds {
    case 0 ..< hour:
      return "\(max(1, Int(seconds / minute)))m"
    case 0 ..< day:
      return "\(Int(seconds / hour))h"
    case 0 ..< week:
      return "\(Int(seconds / day))d"
    case 0 ..< month:
      return "\(Int(seconds / week))w"
    case 0 ..< year:
      return "\(Int(seconds / month))mo"
    default:
      return "\(Int(seconds / year))y"
    }
  }
}
 */

extension Collection {
  func withOffsets(
    _ offsets: [(value: Int, unit: Calendar.Component)],
    stride: Int,
  ) -> [(element: Element, offset: (value: Int, unit: Calendar.Component))] {
    guard offsets.isEmpty == false, stride > 0 else { return [] }

    return enumerated()
      .map { index, element in
        (
          element: element,
          offset: offsets[
            Swift.min(
              index / stride,
              offsets.count - 1,
            )
          ],
        )
      }
  }
}

extension Date {
  func subtract(
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
