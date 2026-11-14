import Foundation

struct DateOffset {
  var components = DateComponents()

  func years(_ value: Int) -> Self {
    var copy = self
    copy.components.year = value
    return copy
  }

  func months(_ value: Int) -> Self {
    var copy = self
    copy.components.month = value
    return copy
  }

  func weeks(_ value: Int) -> Self {
    var copy = self
    copy.components.weekOfYear = value
    return copy
  }

  func days(_ value: Int) -> Self {
    var copy = self
    copy.components.day = value
    return copy
  }

  func hours(_ value: Int) -> Self {
    var copy = self
    copy.components.hour = value
    return copy
  }

  func minutes(_ value: Int) -> Self {
    var copy = self
    copy.components.minute = value
    return copy
  }

  func seconds(_ value: Int) -> Self {
    var copy = self
    copy.components.second = value
    return copy
  }

  func nanoseconds(_ value: Int) -> Self {
    var copy = self
    copy.components.nanosecond = value
    return copy
  }

  func weekdays(_ value: Int) -> Self {
    var copy = self
    copy.components.weekday = value
    return copy
  }

  func weekdayOrdinals(_ value: Int) -> Self {
    var copy = self
    copy.components.weekdayOrdinal = value
    return copy
  }

  func quarters(_ value: Int) -> Self {
    var copy = self
    copy.components.quarter = value
    return copy
  }
}

extension DateOffset {
  static func years(_ value: Int) -> Self {
    Self().years(value)
  }

  static func months(_ value: Int) -> Self {
    Self().months(value)
  }

  static func weeks(_ value: Int) -> Self {
    Self().weeks(value)
  }

  static func days(_ value: Int) -> Self {
    Self().days(value)
  }

  static func hours(_ value: Int) -> Self {
    Self().hours(value)
  }

  static func minutes(_ value: Int) -> Self {
    Self().minutes(value)
  }

  static func seconds(_ value: Int) -> Self {
    Self().seconds(value)
  }

  static func nanoseconds(_ value: Int) -> Self {
    Self().nanoseconds(value)
  }

  static func weekdays(_ value: Int) -> Self {
    Self().weekdays(value)
  }

  static func weekdayOrdinals(_ value: Int) -> Self {
    Self().weekdayOrdinals(value)
  }

  static func quarters(_ value: Int) -> Self {
    Self().quarters(value)
  }
}

extension DateComponents {
  var negated: DateComponents {
    var copy = self

    copy.year = year.map { -$0 }
    copy.quarter = quarter.map { -$0 }
    copy.month = month.map { -$0 }
    copy.weekOfYear = weekOfYear.map { -$0 }
    copy.day = day.map { -$0 }
    copy.hour = hour.map { -$0 }
    copy.minute = minute.map { -$0 }
    copy.second = second.map { -$0 }
    copy.nanosecond = nanosecond.map { -$0 }

    return copy
  }
}

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

  func subtracting(_ offset: DateOffset) -> Date {
    Calendar.current.date(
      byAdding: offset.components.negated,
      to: self,
    ) ?? self
  }

  func adding(_ offset: DateOffset) -> Date {
    Calendar.current.date(
      byAdding: offset.components,
      to: self,
    ) ?? self
  }
}
