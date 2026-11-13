import SwiftUI

struct CachedImage: View {
  let url: URL?

  var body: some View {
    if let url, url.scheme == "assets" {
      AssetCatalogImage(url: url)
    } else {
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

private struct AssetCatalogImage: View {
  let url: URL

  var body: some View {
    Group {
      let name = url.lastPathComponent

      if UIImage(named: name, in: .main, compatibleWith: nil) == nil {
        CachedImageContent(phase: .failure(URLError(.fileDoesNotExist)))
      } else {
        Image(name)
          .resizable()
      }
    }
  }
}

private struct CachedImageContent: View {
  let phase: AsyncImagePhase

  let placeholder = Rectangle().fill(.themePlaceholder)

  var body: some View {
    switch phase {
    case .empty:
      placeholder
        .overlay {
          ProgressView()
        }

    case .failure:
      placeholder
        .overlay {
          Image(systemName: "xmark.circle")
        }

    case .success(let image):
      image
        .resizable()

    @unknown default:
      placeholder
    }
  }
}

enum ImageUrlSession {
  static let shared: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.urlCache = URLCache(
      memoryCapacity: 20 * StorageUnit.mb,
      diskCapacity: 100 * StorageUnit.mb,
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
  let url = URL(string: "https://picsum.photos/600/400")

  let assetUrl = URL(string: "assets:///Album-12033290")

  let size: CGFloat = 200

  VStack {
    LabeledContent("Empty") {
      CachedImageContent(phase: .empty)
        .frame(width: size, height: size)
    }

    LabeledContent("Failure") {
      CachedImageContent(phase: .failure(URLError(.badURL)))
        .frame(width: size, height: size)
    }

    LabeledContent("Success") {
      CachedImage(url: url)
        .frame(width: size, height: size)
        .clipped()
    }

    LabeledContent("Asset Catalog") {
      CachedImage(url: assetUrl)
        .frame(width: size, height: size)
        .clipped()
    }
  }
  .padding()
  .background(.gray.opacity(0.5))
}
#endif
