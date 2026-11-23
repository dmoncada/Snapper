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
        _AdaptiveAlbumDetailView(album: album)
      } else {
        AlbumDetailScrollView(album: album, showMetadata: true)
      }
    }
    .withAlbumDetailLifecycle(album: album)
    .withFullBackground()
  }
}

@available(iOS 27.1, *)
private struct _AdaptiveAlbumDetailView: View {
  let album: Album

  @State private var isLandscape = false
  @State private var hingeStatus: DeviceHinge.Status?

  var body: some View {
    let isHingeOpen = hingeStatus == .partiallyOpen || hingeStatus == .fullyOpen

    ZStack {
      if isHingeOpen, isLandscape {
        AlbumDetailSplitView(album: album)
      } else {
        AlbumDetailScrollView(album: album, showMetadata: true)
      }
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
    )
    .onGeometryChange(for: Bool.self) { geometry in
      geometry.size.width > geometry.size.height
    } action: {
      isLandscape = $0
    }
    .onHingeChange { _, context in
      hingeStatus = context.hinge?.status
    }
  }
}
