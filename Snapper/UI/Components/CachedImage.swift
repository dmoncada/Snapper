import SwiftUI

struct CachedImage: View {
  let url: URL?

  var body: some View {
    AsyncImage(url: url) { phase in
      CachedImageContent(phase: phase)
    }
    .asyncImageURLSession(.images)
  }
}

private struct CachedImageContent: View {
  let phase: AsyncImagePhase

  var body: some View {
    switch phase {
    case .empty:
      ZStack {
        Color.gray
        ProgressView()
          .tint(.white)
      }

    case .success(let image):
      image
        .resizable()
        .scaledToFill()

    case .failure:
      Color.gray

    @unknown default:
      Color.gray
    }
  }
}

enum ImageUrlSession {
  static let shared: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.urlCache = URLCache(
      memoryCapacity: 20 * 1024 * 1024,
      diskCapacity: 100 * 1024 * 1024
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
    let url =
      "https://scontent-sea5-1.cdninstagram.com/v/t51.82787-15/641330379_18562603411030753_5700450649264582620_n.jpg?stp=dst-jpg_e35_tt6&_nc_cat=104&ig_cache_key=MzgzOTEzNTcxNjI5OTkwNzQ0Ng%3D%3D.3-ccb7-5&ccb=7-5&_nc_sid=58cdad&efg=eyJ2ZW5jb2RlX3RhZyI6IkZFRUQueHBpZHMuMTQ0MC5zZHIucmVndWxhcl9waG90by5DMyJ9&_nc_ohc=TYvDWN0YxnwQ7kNvwG3Uoe_&_nc_oc=Adql0g73DyEw_NIHgrbDCFiyoV-T-6-yav4UruKnmL9JdMLSc1HEIj-_PXBVMV29UOU&_nc_zt=23&_nc_ht=scontent-sea5-1.cdninstagram.com&_nc_gid=TXeb6yYoY0fSxWNee4zpCQ&_nc_ss=7b6a8&oh=00_AQMHYh4aRQuCDvzNbjT-jkunrExebPKQLU1oP8aw25mt0g&oe=6AC097FF"

    let size: CGFloat = 200

    VStack {
      Group {
        LabeledContent("Success") {
          CachedImage(url: URL(string: url))
            .frame(width: size, height: size)
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
    }
    .padding()
    .background(.gray.opacity(0.5))
  }
#endif
