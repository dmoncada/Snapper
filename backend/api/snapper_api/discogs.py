from urllib.parse import urljoin

import httpx

from .cache import UpstreamPacer
from .models import AlbumCandidate, AlbumTrack
from .upstream import UpstreamError, get_json


class DiscogsClient:
    def __init__(
        self, client: httpx.AsyncClient, token: str, pacer: UpstreamPacer | None = None
    ):
        self._client = client
        self._token = token
        self._pacer = pacer or UpstreamPacer(1.1)

    async def _get(self, path: str, params: dict | None = None) -> dict:
        if not self._token:
            raise UpstreamError("discogs")
        return await get_json(
            self._client,
            self._pacer,
            "discogs",
            f"https://api.discogs.com/{path}",
            params=params,
            headers={
                "Authorization": f"Discogs token={self._token}",
                "User-Agent": "Snapper/1.0 (metadata API)",
            },
        )

    async def search(
        self, *, query: str | None = None, barcode: str | None = None, limit: int
    ) -> list[AlbumCandidate]:
        params = {"type": "release", "per_page": limit}
        params["barcode" if barcode is not None else "q"] = (
            barcode if barcode is not None else query
        )
        payload = await self._get("database/search", params)
        results = payload.get("results", [])
        if not isinstance(results, list):
            raise UpstreamError("discogs")
        albums = []
        for result in results:
            if not isinstance(result, dict) or not isinstance(result.get("id"), int):
                continue
            raw_title = str(result.get("title") or "")
            artist, separator, title = raw_title.partition(" - ")
            uri = result.get("uri")
            albums.append(
                AlbumCandidate(
                    id=result["id"],
                    artist=artist if separator else "",
                    title=title if separator else raw_title,
                    year=int(result["year"])
                    if str(result.get("year") or "").isdigit()
                    else None,
                    formats=result.get("format") or [],
                    labels=result.get("label") or [],
                    country=result.get("country"),
                    thumbnailUrl=result.get("thumb"),
                    coverImageUrl=result.get("cover_image"),
                    discogsUrl=urljoin("https://www.discogs.com", uri)
                    if isinstance(uri, str)
                    and uri.startswith("/")
                    and not uri.startswith("//")
                    else None,
                )
            )
        return albums

    async def tracks(self, release_id: int) -> list[AlbumTrack]:
        payload = await self._get(f"releases/{release_id}")
        tracks = []
        for item in payload.get("tracklist") or []:
            if item.get("type_") == "heading":
                continue
            title = item.get("title")
            if not isinstance(title, str):
                continue
            position = item.get("position")
            tracks.append(
                AlbumTrack(
                    id=f"discogs-{position or ''}-{title}",
                    position=position,
                    title=title,
                    duration=item.get("duration"),
                    previewUrl=None,
                )
            )
        return tracks
