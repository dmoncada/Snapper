import SwiftUI

struct AlbumHeaderStyle: LabeledContentStyle {
  func makeBody(configuration: Configuration) -> some View {
    VStack(alignment: .leading, spacing: Spacing.xs) {
      configuration.content
        .foregroundStyle(.themePrimary)

      configuration.label
        .foregroundStyle(.accent)
    }
  }
}

extension LabeledContentStyle where Self == AlbumHeaderStyle {
  static var albumHeader: Self { Self() }
}

#if DEBUG
import SwiftData

#Preview(traits: .withSampleData) {
  @Previewable @Query(sort: \Album.selectedAt, order: .reverse) var albums: [Album]

  if let album = albums.last {
    WithColorSchemes {
      VStack(alignment: .leading, spacing: 16) {
        LabeledContent {
          Text(album.title)
            .font(Typography.albumRow.title)
        } label: {
          Text(album.artist)
            .font(Typography.albumRow.artist)
        }
        .labeledContentStyle(.albumHeader)
        .lineLimit(1)
      }
      .padding()
    }
  } else {
    ProgressView()
  }
}
#endif
