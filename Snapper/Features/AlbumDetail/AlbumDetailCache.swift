import Foundation

actor AlbumDetailCache {
  static let shared = AlbumDetailCache()

  private var details: [CacheKey: AlbumDetail] = [:]

  func detail(for key: CacheKey) -> AlbumDetail? {
    details[key]
  }

  func store(_ detail: AlbumDetail, for key: CacheKey) {
    details[key] = detail
  }
}

nonisolated struct CacheKey: Hashable, Sendable {
  let discogsReleaseId: Int
  let storefront: ItunesStorefront
}
