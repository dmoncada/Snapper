import Foundation

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
