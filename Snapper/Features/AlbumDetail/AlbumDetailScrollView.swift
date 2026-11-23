import SwiftUI

struct AlbumDetailScrollView: View {
  @Environment(AlbumDetailViewModel.self) private var vm

  let album: Album
  let showMetadata: Bool

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        AlbumHero(url: album.coverImageUrl)
          .stretchable()

        VStack(alignment: .leading, spacing: Spacing.lg) {
          AlbumHeaderSection(album: album, showFavorite: showMetadata)

          if showMetadata, album.artistInfo.hasInfo {
            AlbumWikipediaSection(album.artistInfo.get())
          }

          if showMetadata, album.albumInfo.hasInfo {
            AlbumWikipediaSection(album.albumInfo.get())
          }

          if showMetadata, let location = album.location {
            AlbumLocationSection(location: location)
          }

          AlbumDetailSection(album: album, showDate: showMetadata)

          AlbumTrackSection(vm: vm, musicUrl: album.musicUrl)
        }
        .padding(Padding.xl)
      }
    }
    .ignoresSafeArea(.all, edges: .top)
    .scrollIndicators(.hidden)
  }
}
