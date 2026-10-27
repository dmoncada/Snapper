import Alamofire
import Foundation

nonisolated struct AlamofireApiClient: ApiClient {
  private let baseUrl: URL
  private let session: Session

  init(baseUrl: URL = .baseUrl) {
    self.baseUrl = baseUrl

    let retryPolicy = Alamofire.RetryPolicy(
      retryLimit: 3,
      exponentialBackoffBase: 2,
      exponentialBackoffScale: 0.5,
      retryableHTTPMethods: [.get],
      retryableHTTPStatusCodes: [408, 429, 500, 502, 503, 504],
      retryableURLErrorCodes: [
        .timedOut,
        .cannotFindHost,
        .cannotConnectToHost,
        .networkConnectionLost,
        .dnsLookupFailed,
        .notConnectedToInternet,
      ],
    )

    let retryAfter = Alamofire.Retrier { request, _, _, completion in
      guard
        request.request?.httpMethod == "GET",
        request.retryCount < 3,
        let response = request.response,
        [408, 429, 500, 502, 503, 504].contains(response.statusCode),
        let header = response.value(forHTTPHeaderField: "Retry-After"),
        let seconds = Int(header.trimmingCharacters(in: .whitespacesAndNewlines)),
        seconds >= 0
      else {
        completion(.doNotRetry)
        return
      }

      completion(.retryWithDelay(TimeInterval(seconds)))
    }

    session = Self.makeSession(
      timeout: 15,
      interceptor: Alamofire.Interceptor(
        retriers: [
          retryAfter,
          retryPolicy,
        ]
      ),
    )
  }

  func health() async throws {
    _ =
      try await session.request(
        baseUrl.appending(path: "health"),
        headers: [
          .accept("application/json"),
          .contentType("application/json"),
        ],
      )
      .validate(statusCode: 200 ..< 300)
      .serializingData(emptyResponseCodes: Set(200 ..< 300))
      .value
  }

  func searchAlbums(
    term: String? = nil,
    barcode: String? = nil,
    limit: Int = 10,
  ) async throws -> [AlbumDto] {
    assert(term != nil || barcode != nil, "Term and barcode cannot both be nil.")

    var parameters = ["limit": String(limit)]

    if let term { parameters["term"] = term }
    if let barcode { parameters["barcode"] = barcode }

    let albums =
      try await session.request(
        baseUrl.appending(path: "albums"),
        parameters: parameters,
        encoder: URLEncodedFormParameterEncoder.default,
        headers: [
          .accept("application/json"),
          .contentType("application/json"),
        ],
      )
      .validate(statusCode: 200 ..< 300)
      .serializingDecodable([AlbumDto].self, decoder: Self.makeDecoder())
      .value

        return albums
  }

  func resolveTracks(
    discogsId: Int,
    albumTitle: String,
    albumArtist: String,
    barcode: String? = nil,
  ) async throws -> [TrackDto] {
    var parameters = [
      "discogs_id": String(discogsId),
      "album_title": albumTitle,
      "album_artist": albumArtist,
    ]

    if let barcode { parameters["barcode"] = barcode }

    return
      try await session.request(
        baseUrl.appending(path: "tracks"),
        parameters: parameters,
        encoder: URLEncodedFormParameterEncoder.default,
        headers: [
          .accept("application/json"),
          .contentType("application/json"),
        ],
      )
      .validate(statusCode: 200 ..< 300)
      .serializingDecodable([TrackDto].self, decoder: Self.makeDecoder())
      .value
  }

  private static func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }

  private static func makeSession(
    timeout: TimeInterval,
    interceptor: (any RequestInterceptor)? = nil,
  ) -> Session {
    let configuration = URLSessionConfiguration.default

    configuration.urlCache = URLCache(
      memoryCapacity: 20 * 1_024 * 1_024,
      diskCapacity: 100 * 1_024 * 1_024,
    )

    configuration.requestCachePolicy = .useProtocolCachePolicy
    configuration.timeoutIntervalForRequest = timeout
    configuration.timeoutIntervalForResource = timeout * 2
    configuration.waitsForConnectivity = true

    return Session(configuration: configuration, interceptor: interceptor)
  }
}

extension ApiClient where Self == AlamofireApiClient {
  static var live: Self { Self() }
  static func live(_ baseUrl: URL) -> Self { Self(baseUrl: baseUrl) }
}

#if DEBUG
import Playgrounds

#Playground("Search albums API") {
  let client: ApiClient = .live

  _ = try await client.searchAlbums(
    term: nil,
    barcode: "843563174807",
    limit: 10,
  )
}

#Playground("Resolve tracks API") {
  let client: ApiClient = .live

  _ = try await client.resolveTracks(
    discogsId: 25_875_376,
    albumTitle: "Time's Arrow",
    albumArtist: "Ladytron",
    barcode: "711297532685",
  )
}
#endif
