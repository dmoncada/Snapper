import Foundation

enum HistoryAlbumImageLoader {
  nonisolated static func load(from urlString: String?) async -> Data? {
    guard
      let urlString,
      let url = URL(string: urlString)
    else { return nil }

    var request = URLRequest(url: url)
    request.timeoutInterval = 15
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
