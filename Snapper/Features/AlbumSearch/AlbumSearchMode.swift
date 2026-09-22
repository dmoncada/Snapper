enum AlbumSearchMode: String, CaseIterable, Identifiable {
  case term
  case barcode

  var id: Self { self }
}
