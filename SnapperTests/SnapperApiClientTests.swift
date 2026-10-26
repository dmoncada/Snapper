// Pending replacement with ApiService tests.
#if false
import Foundation
import Testing

@testable import Snapper

struct SnapperApiClientTests {
  @Test
  func textSearchUsesV2QueryAndCapturesCountryCode() async throws {
    let transport = StubHttpTransport(
      statusCode: 200,
      body: """
        [{"discogs_id":42,"artist":"Radiohead","title":"Kid A","year":2000,"format":["CD"],"label":["Parlophone"],"country":"UK","country_info":{"alpha_2":"GB","alpha_3":"GBR","numeric":"826","name":"United Kingdom"},"thumbnail_url":null,"cover_image_url":null,"discogs_url":"/release/42-Radiohead-Kid-A"}]
        """,
      inspect: { request in
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString.contains("/api/v1/albums/?") == true)
        let items = request.url.flatMap {
          URLComponents(url: $0, resolvingAgainstBaseURL: false)
        }?
        .queryItems
        #expect(items == [URLQueryItem(name: "term", value: "Radiohead Kid A")])
      },
    )
    let client = SnapperApiClient(
      baseUrlString: "http://127.0.0.1:8000",
      transport: transport,
    )

    let albums = try await client.searchAlbums(matching: "Radiohead Kid A")

    #expect(albums.map(\.id) == [42])
    #expect(albums.first?.countryCode == "GB")
    #expect(albums.first?.formats == ["CD"])
    #expect(albums.first?.labels == ["Parlophone"])
    #expect(
      albums.first?.discogsUrl?.absoluteString
        == "https://www.discogs.com/release/42-Radiohead-Kid-A"
    )
  }

  @Test
  func barcodeSearchUsesV2Query() async throws {
    let transport = StubHttpTransport(
      statusCode: 200,
      body: "[]",
      inspect: { request in
        #expect(request.url?.absoluteString.contains("/api/v1/albums/?") == true)
        let items = request.url.flatMap {
          URLComponents(url: $0, resolvingAgainstBaseURL: false)
        }?
        .queryItems
        #expect(items == [URLQueryItem(name: "barcode", value: "123456789012")])
      },
    )
    let client = SnapperApiClient(
      baseUrlString: "http://127.0.0.1:8000",
      transport: transport,
    )

    let albums = try await client.searchAlbums(withBarcode: "123456789012")
    #expect(albums.isEmpty)
  }

  @Test
  func tracklistMapsItunesIdAndDiscogsFallbackId() async throws {
    let transport = StubHttpTransport(
      statusCode: 200,
      body: """
        [{"track_id":123,"track_title":"Everything In Its Right Place","track_position":"1-1","track_duration":"4:11","track_preview_url":"https://example.com/preview.m4a"},{"track_id":null,"track_title":"Untitled","track_position":"1-2","track_duration":"","track_preview_url":null}]
        """,
      inspect: { request in
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString.contains("/api/v1/tracks/?") == true)
        #expect(request.httpBody == nil)
        let items = request.url.flatMap {
          URLComponents(url: $0, resolvingAgainstBaseURL: false)
        }?
        .queryItems
        #expect(items?.first(where: { $0.name == "discogs_id" })?.value == "42")
        #expect(items?.first(where: { $0.name == "album_title" })?.value == "Kid A")
        #expect(items?.first(where: { $0.name == "album_artist" })?.value == "Radiohead")
        #expect(items?.first(where: { $0.name == "barcode" })?.value == "123456789012")
      },
    )
    let client = SnapperApiClient(
      baseUrlString: "http://127.0.0.1:8000",
      transport: transport,
    )

    let result = try await client.resolveTracklist(
      AlbumTracklistRequest(
        discogsReleaseId: 42,
        artist: "Radiohead",
        title: "Kid A",
        barcode: "123456789012",
      )
    )

    #expect(result.source == .itunes(nil))
    #expect(result.tracks.map(\.id) == ["itunes:123", "discogs:42:1"])
    #expect(result.tracks.first?.previewUrl?.absoluteString == "https://example.com/preview.m4a")
  }

  @Test
  func rateLimitProducesUsefulError() async throws {
    let transport = StubHttpTransport(
      statusCode: 429,
      body: #"{"detail":"Rate limit exceeded"}"#,
      inspect: { _ in },
    )
    let client = SnapperApiClient(
      baseUrlString: "http://127.0.0.1:8000",
      transport: transport,
    )

    do {
      _ = try await client.searchAlbums(matching: "Radiohead")
      Issue.record("Expected an HTTP error")
    } catch let error as SnapperApiError {
      #expect(error.errorDescription == "Too many requests. Please try again shortly.")
    }
  }
}
#endif
