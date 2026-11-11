import SwiftUI

struct AlbumSinglePin: View {
  let title: String
  let artist: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading) {
        Text(title)
          .font(.caption)
          .bold()
          .lineLimit(1)

        Text(artist)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .padding(.horizontal)
      .padding(.vertical, 8)
      .frame(maxWidth: 160)
      .background(.regularMaterial, in: .rect(cornerRadius: 12))
    }
    .buttonStyle(.plain)
  }
}
