enum SheetDestination: Hashable, Identifiable {
  case settings
  case create(AlbumEntry)

  var id: String {
    switch self {
    case .settings: "settings"
    case .create: "create"
    }
  }
}
