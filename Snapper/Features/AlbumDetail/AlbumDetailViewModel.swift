import Foundation
import Observation

@MainActor
@Observable
final class AlbumDetailViewModel {
  private(set) var state = AlbumDetailState.loading
  private(set) var detail: AlbumDetail?

  var loadAttempt = 0

  private let selection: AlbumSelection
  private let loader: AlbumDetailLoader

  convenience init(selection: AlbumSelection) {
    let token = Bundle.main.object(forInfoDictionaryKey: "DISCOGS_TOKEN") as? String ?? ""
    let storefront = ItunesStorefront()

    self.init(
      selection: selection,
      loader: AlbumDetailLoader(
        itunesClient: ItunesClient(storefront: storefront),
        discogsClient: DiscogsClient(token: token),
        storefront: storefront,
        cache: .shared))
  }

  init(selection: AlbumSelection, loader: AlbumDetailLoader) {
    self.selection = selection
    self.loader = loader
  }

  func load() async {
    state = .loading
    do {
      let detail = try await loader.load(selection)
      try Task.checkCancellation()
      self.detail = detail
      state = .loaded

    } catch is CancellationError {
      // SwiftUI cancels the load when the detail screen disappears.

    } catch {
      detail = nil
      state = .error(error.localizedDescription)
    }
  }

  func retry() {
    loadAttempt += 1
  }
}
