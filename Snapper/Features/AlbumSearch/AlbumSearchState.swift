enum AlbumSearchState: Equatable {
  case idle
  case searching
  case results
  case empty
  case error(String)
}
