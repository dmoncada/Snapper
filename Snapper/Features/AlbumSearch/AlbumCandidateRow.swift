import SwiftUI

struct AlbumCandidateRow: View {
  let candidate: AlbumCandidate

  var body: some View {
    VStack(alignment: .leading) {
      Text(candidate.title)
        .bold()

      if candidate.artist.count > 0 {
        Text(candidate.artist)
          .foregroundStyle(.secondary)
      }

      if candidate.displayMetadata.count > 0 {
        Text(candidate.displayMetadata)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }
}
