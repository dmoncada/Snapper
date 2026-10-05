#if DEBUG
import Foundation

struct PreviewAlbumRecord: Decodable {
  let id: UUID
  let title: String
  let selectedAt: String
  let thumbnailUrlString: String?
  let coverImageUrlString: String?
}
#endif
