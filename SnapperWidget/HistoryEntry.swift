import WidgetKit

struct HistoryEntry: TimelineEntry {
  let date: Date
  let albums: [HistoryAlbum]
}

#if DEBUG
extension HistoryEntry {
  static func preview(albumCount: Int) async -> Self {
    let appBundleUrl = Bundle
      .main
      .bundleURL
      .deletingLastPathComponent()
      .deletingLastPathComponent()

    let sampleUrl =
      (Bundle.allBundles + [Bundle.main])
      .compactMap { $0.url(forResource: "albums", withExtension: "json") }
      .first
      ?? Bundle(url: appBundleUrl)?.url(forResource: "albums", withExtension: "json")

    guard let sampleUrl else {
      fatalError("Unable to find the sample albums.json for the widget preview.")
    }

    do {
      let data = try Data(contentsOf: sampleUrl)
      let records = Array(
        try JSONDecoder()
          .decode([PreviewAlbumRecord].self, from: data)
          .sorted { $0.selectedAt > $1.selectedAt }
          .prefix(albumCount)
      )

      var imageData = [Data?](repeating: nil, count: records.count)

      await withTaskGroup(of: (Int, Data?).self) { group in
        for (index, record) in records.enumerated() {
          let imageUrlString = record.thumbnailUrlString ?? record.coverImageUrlString
          group.addTask {
            let data = await HistoryAlbumImageLoader.load(from: imageUrlString)
            return (index, data)
          }
        }

        for await (index, data) in group {
          imageData[index] = data
        }
      }

      let albums = records.enumerated()
        .map { index, record in
          HistoryAlbum(
            id: record.id,
            title: record.title,
            imageData: imageData[index],
          )
        }

      return Self(date: .now, albums: albums)
    } catch {
      fatalError("Unable to load sample albums for the widget preview: \(error)")
    }
  }
}
#endif
