import SwiftUI

@available(iOS 27.1, *)
struct AlbumDetailSplitView: View {
  @Environment(AlbumDetailViewModel.self) private var vm

  let album: Album

  var body: some View {
    ArrangementView {
      ScrollView {
        VStack(spacing: 0) {
          AlbumHero(url: album.coverImageUrl)
            .stretchable()

          VStack(alignment: .leading, spacing: Spacing.lg) {
            AlbumHeaderSection(album: album)

            if album.artistInfo.hasInfo {
              AlbumWikipediaSection(album.artistInfo.get())
            }

            if album.albumInfo.hasInfo {
              AlbumWikipediaSection(album.albumInfo.get())
            }

            if let location = album.location {
              AlbumLocationSection(location: location)
            }
          }
          .padding(Padding.xl)
        }
      }
      .splitArrangementLayoutSize(idealWidth: 475)
      .ignoresSafeArea(.all, edges: .top)
      .scrollIndicators(.hidden)
    } secondary: {
      ScrollView {
        VStack {
          AlbumDetailSection(album: album)

          AlbumTrackSection(vm: vm, musicUrl: album.musicUrl)
        }
        .padding(Padding.xl)
      }
      // .splitArrangementLayoutRatio(0.45)
      .scrollIndicators(.hidden)
    }
    .arrangementViewStyle(.split.axes(.horizontal))
  }
}
