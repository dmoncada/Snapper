import httpx

from .cache import UpstreamPacer
from .matching import best_artist, best_collection
from .models import AlbumTrack, TracklistResponse
from .upstream import UpstreamError, get_json


class ItunesClient:
    def __init__(self, client: httpx.AsyncClient, pacer: UpstreamPacer | None = None):
        self._client = client
        self._pacer = pacer or UpstreamPacer(3.1)

    async def _get(self, path: str, params: dict) -> list[dict]:
        payload = await get_json(
            self._client,
            self._pacer,
            "itunes",
            f"https://itunes.apple.com/{path}",
            params={**params, "country": "us"},
            headers={"User-Agent": "Snapper/1.0 (metadata API)"},
        )
        results = payload.get("results", [])
        if not isinstance(results, list):
            raise UpstreamError("itunes")
        return [item for item in results if isinstance(item, dict)]

    async def _tracks(self, collection: dict) -> TracklistResponse | None:
        collection_id = collection.get("collectionId")
        if not isinstance(collection_id, int):
            return None
        results = await self._get("lookup", {"id": collection_id, "entity": "song"})
        tracks = []
        for item in results:
            track_id, title, track_number = (
                item.get("trackId"),
                item.get("trackName"),
                item.get("trackNumber"),
            )
            if (
                not isinstance(track_id, int)
                or not isinstance(title, str)
                or not isinstance(track_number, int)
            ):
                continue
            disc_number = item.get("discNumber") or 1
            millis = item.get("trackTimeMillis")
            duration = (
                f"{millis // 60_000}:{millis // 1000 % 60:02}"
                if isinstance(millis, int)
                else None
            )
            tracks.append(
                AlbumTrack(
                    id=f"itunes-{track_id}",
                    position=f"{disc_number}-{track_number}",
                    title=title,
                    duration=duration,
                    previewUrl=item.get("previewUrl"),
                )
            )
        if not tracks:
            return None
        tracks.sort(key=lambda track: tuple(map(int, track.position.split("-"))))
        return TracklistResponse(
            source="itunes",
            itunesUrl=collection.get("collectionViewUrl"),
            tracks=tracks,
        )

    async def resolve_tracks(self, artist: str, title: str) -> TracklistResponse | None:
        albums = await self._get(
            "search",
            {
                "term": f"{artist} {title}",
                "media": "music",
                "entity": "album",
                "limit": 25,
            },
        )
        collection = best_collection(albums, artist, title)
        if collection is None:
            artists = await self._get(
                "search",
                {
                    "term": artist,
                    "media": "music",
                    "entity": "musicArtist",
                    "limit": 10,
                },
            )
            matched_artist = best_artist(artists, artist)
            if matched_artist is not None:
                albums = await self._get(
                    "lookup",
                    {
                        "id": matched_artist["artistId"],
                        "entity": "album",
                        "limit": 200,
                    },
                )
                collection = best_collection(albums, artist, title)
        if collection is None:
            return None
        return await self._tracks(collection)
