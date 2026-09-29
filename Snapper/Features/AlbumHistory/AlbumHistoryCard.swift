import SwiftUI

struct AlbumHistoryCard: View {
  let entry: AlbumEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      AlbumCover(url: URL(string: entry.coverImageUrlString ?? ""))
        .roundedOutline(lineWidth: 1)

      HStack {
        AlbumHeader(entry: entry)
          .frame(maxWidth: .infinity, alignment: .leading)
          .minimumScaleFactor(0.5)
          .lineLimit(1)

        Spacer()

        Text((entry.selectedAt.shortRelativeTime(to: .now)))
          .padding(Padding.md)
          .font(.sligoilMicroMedium(.caption2))
          .foregroundStyle(.themePrimaryInverted)
          .roundedOutline(lineWidth: 1, color: .themePrimaryInverted)
      }
      .frame(height: 40)
    }
  }
}

private struct AlbumCover: View {
  let url: URL?

  var body: some View {
    Color.clear
      .frame(maxWidth: .infinity)
      .aspectRatio(1, contentMode: .fit)
      .overlay {
        CachedImage(url: url)
          .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
          )
          .clipped()
      }
  }
}

extension Date {
  fileprivate func shortRelativeTime(to now: Date = .now) -> String {
    let seconds = max(0, now.timeIntervalSince(self))

    let minute = 60.0
    let hour = 60.0 * minute
    let day = 24.0 * hour
    let week = 7.0 * day
    let month = 30.0 * day
    let year = 365.0 * day

    switch seconds {
    case 0 ..< hour:
      return "\(max(1, Int(seconds / minute)))m"
    case 0 ..< day:
      return "\(Int(seconds / hour))h"
    case 0 ..< week:
      return "\(Int(seconds / day))d"
    case 0 ..< month:
      return "\(Int(seconds / week))w"
    case 0 ..< year:
      return "\(Int(seconds / month))mo"
    default:
      return "\(Int(seconds / year))y"
    }
  }
}

#if DEBUG
  import SwiftData

  #Preview(traits: .modifier(SampleData())) {
    @Previewable @Query var entries: [AlbumEntry]

    if let entry = entries.first {
      ScrollView(.vertical) {
        ForEach([300, 200, 100], id: \.self) { size in
          AlbumHistoryCard(entry: entry)
            .frame(width: size)
        }
      }
      .padding()
      .background(.gray.opacity(0.5))

    } else {
      EmptyView()
    }
  }
#endif
