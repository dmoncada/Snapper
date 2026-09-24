enum AlbumSearchState: Equatable {
  case idle
  case recognizing
  case searching
  case results
  case empty
  case unreadable
  case error(String)
}
