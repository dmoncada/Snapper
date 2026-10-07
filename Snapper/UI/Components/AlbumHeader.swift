import SwiftUI

struct AlbumHeader: View {
  init(entry: AlbumEntry, size: ControlSize = .small) {
    self.init(
      title: entry.title,
      artist: entry.artist,
      size: size,
    )
  }

  init(title: String, artist: String, size: ControlSize = .small) {
    self.title = title
    self.artist = artist
    self.size = size
  }

  private let title: String
  private let artist: String
  private let size: ControlSize

  var body: some View {
    LabeledContent {
      Text(artist)
    } label: {
      Text(title)
    }
    .labeledContentStyle(.albumHeader(controlSize: size))
  }
}

#if DEBUG
private struct TestAlbumHeader: View {
  var body: some View {
    HStack(spacing: 32) {
      AlbumHeader(title: "Galore", artist: "Dragonette", size: .large)
      AlbumHeader(title: "Galore", artist: "Dragonette", size: .small)
    }
    .padding()
    .frame(maxWidth: .infinity)
  }
}

#Preview {
  VStack(spacing: 0) {
    TestAlbumHeader()
      .background(.themePrimary)
      .environment(\.colorScheme, .light)

    TestAlbumHeader()
      .background(.themePrimary)
      .environment(\.colorScheme, .dark)
  }
}
#endif
