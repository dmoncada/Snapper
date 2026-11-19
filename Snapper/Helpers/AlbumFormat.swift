import Foundation

enum AlbumFormat: String, CaseIterable {
  case cd
  case vinyl
  case cassette

  var resource: LocalizedStringResource {
    switch self {
    case .cd:
      .formatsCd
    case .vinyl:
      .formatsVinyl
    case .cassette:
      .formatsCassette
    }
  }
}
