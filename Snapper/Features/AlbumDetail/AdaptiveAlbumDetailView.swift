import SwiftUI

struct AdaptiveAlbumDetailView: View {
  let album: Album
  let showMetadata: Bool

  init(
    album: Album,
    showMetadata: Bool = true,
  ) {
    self.album = album
    self.showMetadata = showMetadata
  }

  var body: some View {
    Group {
      if #available(iOS 27.1, *) {
        HingeAwareView {
          AlbumDetailSplitView(album: album)
        } fallback: {
          AlbumDetailScrollView(album: album, showMetadata: showMetadata)
        }
      } else {
        AlbumDetailScrollView(album: album, showMetadata: showMetadata)
      }
    }
    .withAlbumDetailLifecycle(album: album)
    .withFullBackground()
  }
}
