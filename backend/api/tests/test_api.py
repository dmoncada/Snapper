import asyncio

import httpx

from snapper_api.cache import UpstreamPacer
from snapper_api.discogs import DiscogsClient
from snapper_api.itunes import ItunesClient
from snapper_api.main import create_app
from snapper_api.service import MetadataService


def run_scenario(responder, exercise):
    async def run():
        calls = []

        def handle(request: httpx.Request) -> httpx.Response:
            calls.append(request)
            return responder(request)

        async with httpx.AsyncClient(transport=httpx.MockTransport(handle)) as upstream:
            service = MetadataService(
                DiscogsClient(upstream, "test-token", UpstreamPacer(0)),
                ItunesClient(upstream, UpstreamPacer(0)),
            )
            app = create_app(service)
            async with app.router.lifespan_context(app):
                async with httpx.AsyncClient(
                    transport=httpx.ASGITransport(app=app), base_url="http://testserver"
                ) as client:
                    await exercise(client, calls)

    asyncio.run(run())


def sample_discogs_result() -> dict:
    return {
        "id": 42, "title": "Radiohead - Kid A", "year": "2000",
        "format": ["CD"], "label": ["Parlophone"], "country": "UK",
        "thumb": "https://i.discogs.com/thumb", "cover_image": "https://i.discogs.com/cover",
        "uri": "/release/42-Radiohead-Kid-A",
    }


def test_text_and_barcode_search_use_app_limits_and_cache():
    def responder(request):
        assert request.url.host == "api.discogs.com"
        assert request.url.path == "/database/search"
        assert request.headers["Authorization"] == "Discogs token=test-token"
        return httpx.Response(200, json={"results": [sample_discogs_result()]})

    async def exercise(client, calls):
        text = await client.get("/v1/albums/search", params={"q": "Radiohead"})
        assert text.status_code == 200
        assert text.json()[0] == {
            "id": 42, "artist": "Radiohead", "title": "Kid A", "year": 2000,
            "formats": ["CD"], "labels": ["Parlophone"], "country": "UK",
            "thumbnailUrl": "https://i.discogs.com/thumb",
            "coverImageUrl": "https://i.discogs.com/cover",
            "discogsUrl": "https://www.discogs.com/release/42-Radiohead-Kid-A",
        }
        assert (await client.get("/v1/albums/search", params={"q": "Radiohead"})).status_code == 200
        barcode = await client.get("/v1/albums/by-barcode/123456789012")
        assert barcode.status_code == 200
        assert len(calls) == 2
        assert calls[0].url.params["per_page"] == "10"
        assert calls[0].url.params["q"] == "Radiohead"
        assert calls[1].url.params["per_page"] == "5"
        assert calls[1].url.params["barcode"] == "123456789012"

    run_scenario(responder, exercise)


def test_itunes_album_match_returns_sorted_preview_tracks():
    def responder(request):
        if request.url.path == "/search":
            assert request.url.params["country"] == "us"
            return httpx.Response(200, json={"results": [{
                "artistName": "Radiohead", "collectionName": "Kid A",
                "collectionId": 99, "collectionViewUrl": "https://music.apple.com/album/99",
            }]})
        assert request.url.path == "/lookup"
        return httpx.Response(200, json={"results": [
            {"trackId": 2, "trackName": "Second", "trackNumber": 2, "discNumber": 1,
             "trackTimeMillis": 125000, "previewUrl": "https://audio-ssl.itunes.apple.com/2"},
            {"trackId": 1, "trackName": "First", "trackNumber": 1, "discNumber": 1},
        ]})

    async def exercise(client, calls):
        result = await client.post("/v1/tracklists/resolve", json={
            "discogsReleaseId": 42, "artist": "Radiohead", "title": "Kid A",
        })
        assert result.status_code == 200
        body = result.json()
        assert body["source"] == "itunes"
        assert body["itunesUrl"] == "https://music.apple.com/album/99"
        assert [track["id"] for track in body["tracks"]] == ["itunes-1", "itunes-2"]
        assert body["tracks"][1]["duration"] == "2:05"
        assert len(calls) == 2

    run_scenario(responder, exercise)


def test_artist_search_path_and_no_match_fall_back_to_discogs():
    def responder(request):
        if request.url.path == "/search" and request.url.params["entity"] == "album":
            return httpx.Response(200, json={"results": []})
        if request.url.path == "/search" and request.url.params["entity"] == "musicArtist":
            return httpx.Response(200, json={"results": [{"artistName": "Radiohead", "artistId": 7}]})
        if request.url.path == "/lookup":
            return httpx.Response(200, json={"results": []})
        assert request.url.path == "/releases/42"
        return httpx.Response(200, json={"tracklist": [
            {"type_": "heading", "title": "Side A"},
            {"position": "A1", "title": "Everything In Its Right Place", "duration": "4:11"},
        ]})

    async def exercise(client, calls):
        result = await client.post("/v1/tracklists/resolve", json={
            "discogsReleaseId": 42, "artist": "Radiohead", "title": "Kid A",
        })
        assert result.status_code == 200
        assert result.json()["source"] == "discogs"
        assert result.json()["tracks"][0]["id"] == "discogs-A1-Everything In Its Right Place"
        assert len(calls) == 4

    run_scenario(responder, exercise)


def test_itunes_error_falls_back_and_discogs_error_is_reported():
    def responder(request):
        if request.url.host == "itunes.apple.com":
            return httpx.Response(503)
        return httpx.Response(429)

    async def exercise(client, calls):
        result = await client.post("/v1/tracklists/resolve", json={
            "discogsReleaseId": 42, "artist": "Radiohead", "title": "Kid A",
        })
        assert result.status_code == 503
        assert result.json() == {"detail": "discogs is temporarily unavailable"}
        assert len(calls) == 2

    run_scenario(responder, exercise)


def test_itunes_error_returns_discogs_tracklist_when_fallback_succeeds():
    def responder(request):
        if request.url.host == "itunes.apple.com":
            return httpx.Response(503)
        assert request.url.path == "/releases/42"
        return httpx.Response(200, json={"tracklist": [
            {"position": "1", "title": "Fallback Song", "duration": "3:20"},
        ]})

    async def exercise(client, calls):
        result = await client.post("/v1/tracklists/resolve", json={
            "discogsReleaseId": 42, "artist": "Radiohead", "title": "Kid A",
        })
        assert result.status_code == 200
        assert result.json()["source"] == "discogs"
        assert result.json()["tracks"][0]["title"] == "Fallback Song"
        assert len(calls) == 2

    run_scenario(responder, exercise)


def test_itunes_artist_lookup_can_find_album_after_initial_miss():
    def responder(request):
        if request.url.path == "/search" and request.url.params["entity"] == "album":
            return httpx.Response(200, json={"results": []})
        if request.url.path == "/search" and request.url.params["entity"] == "musicArtist":
            return httpx.Response(200, json={"results": [{"artistName": "Radiohead", "artistId": 7}]})
        if request.url.path == "/lookup" and request.url.params["entity"] == "album":
            return httpx.Response(200, json={"results": [{
                "artistName": "Radiohead", "collectionName": "Kid A", "collectionId": 99,
            }]})
        assert request.url.path == "/lookup" and request.url.params["entity"] == "song"
        return httpx.Response(200, json={"results": [{
            "trackId": 1, "trackName": "First", "trackNumber": 1,
        }]})

    async def exercise(client, calls):
        result = await client.post("/v1/tracklists/resolve", json={
            "discogsReleaseId": 42, "artist": "Radiohead", "title": "Kid A",
        })
        assert result.status_code == 200
        assert result.json()["source"] == "itunes"
        assert len(calls) == 4

    run_scenario(responder, exercise)


def test_input_validation_and_inbound_limit():
    def responder(_request):
        return httpx.Response(200, json={"results": []})

    async def exercise(client, calls):
        assert (await client.get("/v1/albums/search", params={"q": " "})).status_code == 422
        assert (await client.get("/v1/albums/by-barcode/not-a-barcode")).status_code == 422
        assert (await client.post("/v1/tracklists/resolve", json={
            "discogsReleaseId": -1, "artist": "A", "title": "B",
        })).status_code == 422
        for _ in range(57):
            assert (await client.get("/v1/albums/search", params={"q": "A"})).status_code == 200
        limited = await client.get("/v1/albums/search", params={"q": "B"})
        assert limited.status_code == 429
        assert limited.headers["Retry-After"] == "60"
        assert len(calls) == 1

    run_scenario(responder, exercise)
