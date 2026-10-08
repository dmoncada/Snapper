"""Exercise the running API with the same request shapes used by the iOS app."""

import sys

import httpx


def main(base_url: str) -> None:
    with httpx.Client(base_url=base_url, timeout=45) as client:
        health = client.get("/health")
        assert health.status_code == 200 and health.json() == {"status": "ok"}

        search = client.get("/v1/albums/search", params={"q": "Radiohead Kid A"})
        assert search.status_code == 200, search.text
        candidates = search.json()
        assert candidates and isinstance(candidates[0]["id"], int)
        assert "coverImageUrl" in candidates[0]
        print(f"text search: {len(candidates)} candidates")

        repeat = client.get("/v1/albums/search", params={"q": "Radiohead Kid A"})
        assert repeat.status_code == 200 and repeat.json() == candidates
        print("repeat search: stable cached response")

        barcode = client.get("/v1/albums/by-barcode/123456789012")
        assert barcode.status_code == 200 and isinstance(barcode.json(), list), barcode.text
        print(f"barcode search: {len(barcode.json())} candidates")

        candidate = next(
            (item for item in candidates if item["artist"].casefold() == "radiohead" and item["title"].casefold() == "kid a"),
            candidates[0],
        )
        body = {
            "discogsReleaseId": candidate["id"],
            "artist": candidate["artist"], "title": candidate["title"],
        }
        tracks = client.post("/v1/tracklists/resolve", json=body)
        assert tracks.status_code == 200, tracks.text
        result = tracks.json()
        assert result["source"] in ("itunes", "discogs") and result["tracks"]
        print(f"tracklist: {result['source']}, {len(result['tracks'])} tracks")

        fallback = client.post("/v1/tracklists/resolve", json={
            "discogsReleaseId": candidate["id"],
            "artist": "No matching artist xyz 97531",
            "title": "No matching album xyz 97531",
        })
        assert fallback.status_code == 200, fallback.text
        assert fallback.json()["source"] == "discogs"
        print(f"unmatched iTunes fallback: {len(fallback.json()['tracks'])} Discogs tracks")

        assert client.get("/v1/albums/search", params={"q": " "}).status_code == 422
        assert client.get("/v1/albums/by-barcode/invalid").status_code == 422
        assert client.post("/v1/tracklists/resolve", json={"discogsReleaseId": -1, "artist": "A", "title": "B"}).status_code == 422
        print("invalid input: rejected")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8765")
