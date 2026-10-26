#if DEBUG
import Foundation

struct PreviewAlbumRecord: Decodable {
  let id: UUID
  let title: String
  let selectedAt: String
  let thumbnailUrl: URL?
  let coverImageUrl: URL?
}
#endif
