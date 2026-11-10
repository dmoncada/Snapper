enum Constants {
  static let appId = "net.dmoncada.Snapper"
  static let appGroup = "group.net.dmoncada.Snapper"
}

enum Features: String {
  case search
  case detail
  case history
}

nonisolated enum StorageUnit {
  static let kb = 1_024
  static let mb = 1_024 * kb
  static let gb = 1_024 * mb
}
