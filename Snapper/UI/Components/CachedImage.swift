import SwiftUI

struct CachedImage: View {
  let url: URL?

  var body: some View {
    #if compiler(>=6.4)
    if #available(iOS 27, *) {
      _CachedImage27(url: url)
    } else {
      _CachedImage(url: url)
    }
    #else
    _CachedImage(url: url)
    #endif
  }
}

#if compiler(>=6.4)
@available(iOS 27, *)
private struct _CachedImage27: View {
  let url: URL?

  var body: some View {
    AsyncImage(url: url) { phase in
      CachedImageContent(phase: phase)
    }
    .asyncImageURLSession(.images)
  }
}
#endif

private struct _CachedImage: View {
  let url: URL?

  @State private var phase: AsyncImagePhase = .empty

  var body: some View {
    CachedImageContent(phase: phase)
      .task(id: url) {
        await loadImage()
      }
  }

  private func loadImage() async {
    guard let url else {
      phase = .failure(URLError(.badURL))
      return
    }

    phase = .empty

    do {
      let (data, response) = try await URLSession.images.data(from: url)

      try Task.checkCancellation()

      guard
        let response = response as? HTTPURLResponse,
        200 ..< 300 ~= response.statusCode,
        let uiImage = UIImage(data: data)
      else {
        throw URLError(.badServerResponse)
      }

      phase = .success(Image(uiImage: uiImage))
    } catch {
      if Task.isCancelled { return }
      phase = .failure(error)
    }
  }
}

private struct CachedImageContent: View {
  let phase: AsyncImagePhase

  let placeholder = Rectangle().fill(.placeholder)

  var body: some View {
    switch phase {
    case .empty:
      ZStack {
        placeholder
        ProgressView()
      }

    case .success(let image):
      image
        .resizable()
        .scaledToFill()

    case .failure:
      placeholder

    @unknown default:
      placeholder
    }
  }
}

enum ImageUrlSession {
  static let shared: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.urlCache = URLCache(
      memoryCapacity: 20 * 1024 * 1024,
      diskCapacity: 100 * 1024 * 1024,
    )
    configuration.requestCachePolicy = .useProtocolCachePolicy

    return URLSession(configuration: configuration)
  }()
}

extension URLSession {
  static var images: URLSession { ImageUrlSession.shared }
}

#if DEBUG
#Preview {
  let url = "https://picsum.photos/600/400"

  let size: CGFloat = 200

  VStack {
    LabeledContent("Success") {
      CachedImage(url: URL(string: url))
        .frame(width: size, height: size)
        .clipped()
    }

    LabeledContent("Empty") {
      CachedImageContent(phase: .empty)
        .frame(width: size, height: size)
    }

    LabeledContent("Failure") {
      CachedImageContent(phase: .failure(URLError(.badURL)))
        .frame(width: size, height: size)
    }
  }
  .padding()
  .background(.gray.opacity(0.5))
}
#endif
