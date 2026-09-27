import SwiftUI

struct AlbumCandidateRow: View {
  let candidate: AlbumCandidate

  var body: some View {
    HStack {
      AlbumThumbnail(url: candidate.thumbnailUrl)

      VStack(alignment: .leading, spacing: Spacing.xs) {
        Text(candidate.title)
          .font(.sligoilMicroBold(.caption))

        Text(candidate.artist)
          .font(.sligoilMicro(.caption2))
      }
      .minimumScaleFactor(0.5)
      .lineLimit(1)

      Spacer()

      HStack(spacing: Spacing.xs) {
        if let year = candidate.year {
          Text(String(year))
            .padding(Padding.md)
            .roundedOutline(radius: Radius.md, lineWidth: 1)
        }

        if let format = candidate.formats.first {
          Text(format)
            .padding(Padding.md)
            .roundedOutline(radius: Radius.md, lineWidth: 1)
        }
      }
      .font(.sligoilMicroMedium(.caption2))
    }
    .frame(maxWidth: .infinity)
  }
}

struct AlbumThumbnail: View {
  let url: URL?

  var body: some View {
    AsyncImage(url: url) { image in
      image
        .resizable()
        .scaledToFill()

    } placeholder: {
      ProgressView()
    }
    .frame(width: 64, height: 64)
    .clipShape(.rect(cornerRadius: Radius.sm))
    .asyncImageURLSession(.images)
  }
}

#Preview {
  let album = AlbumCandidate(
    id: 21491,
    artist: "Radiohead",
    title: "OK Computer",
    year: 1997,
    formats: ["CD", "Vinyl", "Cassette"],
    labels: ["Parlophone"],
    country: "United Kingdom",
    thumbnailUrl: URL(
      string:
        "https://i.discogs.com/OaKbbnsKGXwq2llV8ZlLi-QJgKz2S-Wm3NdJfmHKpgU/rs:fit/g:sm/q:40/h:150/w:150/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9SLTg2NjQz/ODQtMTY5NzQ3NDg3/Ny0zMTYxLmpwZWc.jpeg",
    ),
    coverImageUrl: URL(
      string:
        "https://i.discogs.com/YTJxCXA7Z04Ve01kFU5EEsOVN6Xik62J7zgNbCtOBlk/rs:fit/g:sm/q:90/h:601/w:600/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9SLTg2NjQz/ODQtMTY5NzQ3NDg3/Ny0zMTYxLmpwZWc.jpeg",
    ),
    discogsUrl: URL(string: "https://www.discogs.com/master/21491")
  )

  VStack(spacing: 0) {
    AlbumCandidateRow(candidate: album)
      .padding()
      .frame(height: 150)
      .background(.themePrimary)
      .colorScheme(.light)

    AlbumCandidateRow(candidate: album)
      .padding()
      .frame(height: 150)
      .background(.themePrimary)
      .colorScheme(.dark)
  }
}
