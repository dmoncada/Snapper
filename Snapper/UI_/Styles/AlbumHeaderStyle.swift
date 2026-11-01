import SwiftUI

struct AlbumHeaderStyle: LabeledContentStyle {
  @Environment(\.controlSize) private var controlSize

  private let defaultStyles: (Font.TextStyle, Font.TextStyle) = (
    .headline, .subheadline,
  )

  private let styles: [ControlSize: (Font.TextStyle, Font.TextStyle)] = [
    .small: (
      .caption,
      .caption2,
    ),
    .regular: (
      .headline,
      .subheadline,
    ),
    .large: (
      .title2,
      .title3,
    ),
  ]

  func makeBody(configuration: Configuration) -> some View {
    let (titleStyle, artistStyle) = styles[controlSize] ?? defaultStyles

    VStack(alignment: .leading, spacing: Spacing.xs) {
      configuration.content
        .font(.sligoilMicroBold(titleStyle))
        .foregroundStyle(.themePrimaryInverted)

      configuration.label
        .font(.sligoilMicro(artistStyle))
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

  let sizes: [ControlSize] = [.small, .regular, .large]

  if let album = albums.first {
    WithColorSchemes {
      VStack(alignment: .leading, spacing: 16) {
        ForEach(sizes, id: \.self) { size in
          LabeledContent(album.artist, value: album.title)
            .labeledContentStyle(.albumHeader)
            .controlSize(size)
            .lineLimit(1)
        }
      }
      .padding()
    }
  } else {
    ProgressView()
  }
}
#endif
