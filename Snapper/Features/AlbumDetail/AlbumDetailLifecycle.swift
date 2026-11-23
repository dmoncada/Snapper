import SwiftData
import SwiftUI

struct AlbumDetailLifecycle: ViewModifier {
  @Environment(AlbumDetailViewModel.self) private var viewModel

  @Environment(\.previewPlayer) private var player

  let album: Album

  func body(content: Content) -> some View {
    content
      .task(id: album.persistentModelID) {
        await viewModel.resolveTracks(for: album)
      }
      .onDisappear {
        Task {
          await player.stopImmediately()
        }
      }
  }
}

extension View {
  func withAlbumDetailLifecycle(album: Album) -> some View {
    modifier(AlbumDetailLifecycle(album: album))
  }
}
