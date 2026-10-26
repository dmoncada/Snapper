import Foundation

enum HistoryAlbumImageLoader {
  nonisolated static func load(from url: URL?) async -> Data? {
    guard let url else { return nil }

    var request = URLRequest(url: url)
    request.timeoutInterval = 3
    request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
    request.setValue("https://www.discogs.com/", forHTTPHeaderField: "Referer")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      guard
        let response = response as? HTTPURLResponse,
        200 ..< 300 ~= response.statusCode
      else { return nil }

      return data
    } catch {
      return nil
    }
  }
}
