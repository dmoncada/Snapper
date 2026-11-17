"""Wikipedia extracts for selected Discogs releases."""

import logging

import httpx2
from fastapi import HTTPException
from markdownify import markdownify
from pydantic import ValidationError
from redis_fastapi import CacheBackend

from app.api.models import AlbumWikiResponse, WikipediaExtract
from app.core.cache import DAY, HOUR
from app.core.matching_wiki import select_album_page, select_artist_page
from app.providers.discogs.catalog import DiscogsCatalog
from app.providers.discogs.models import ReleaseRequest
from app.providers.wikipedia.client import WikipediaClient
from app.providers.wikipedia.models import SearchPage

logger = logging.getLogger(__name__)


async def get_album_wiki(
    album_id: int,
    discogs: DiscogsCatalog,
    wikipedia: WikipediaClient,
    cache: CacheBackend,
) -> AlbumWikiResponse:
    key = f"catalog:v2:wikipedia:release:{album_id}"
    cached = await cache.get(key)
    if cached is not None:
        try:
            return AlbumWikiResponse.model_validate(cached)
        except ValidationError:
            pass

    release = await discogs.get_release(ReleaseRequest(release_id=album_id))
    artist_name = release.artists[0].name if len(release.artists) == 1 else None
    if not artist_name or artist_name.casefold() == "various":
        result = AlbumWikiResponse()
    else:
        try:
            artist_page = select_artist_page(
                (await wikipedia.search(artist_name)).pages, artist_name
            )
            album_page = select_album_page(
                (await wikipedia.search(f"{release.title} {artist_name}")).pages,
                release.title,
                artist_name,
            )
            result = AlbumWikiResponse(
                album=await _extract(wikipedia, album_page),
                artist=await _extract(wikipedia, artist_page),
            )
        except (httpx2.HTTPError, ValidationError) as error:
            logger.warning(
                "Wikipedia lookup failed for release %s: %s", album_id, error
            )
            raise HTTPException(
                status_code=502, detail="Wikipedia information unavailable"
            ) from error

    ttl = 7 * DAY if result.album or result.artist else HOUR
    await cache.set(key, result.model_dump(mode="json"), ttl=ttl)
    return result


async def _extract(
    wikipedia: WikipediaClient, page: SearchPage | None
) -> WikipediaExtract | None:
    if page is None:
        return None

    summary = await wikipedia.summary(page.key)
    if summary is None or summary.type == "disambiguation" or not summary.extract:
        return None

    return WikipediaExtract(
        title=summary.title,
        extract=summary.extract,
        extract_markdown=(
            markdownify(summary.extract_html).strip()
            if summary.extract_html
            else summary.extract
        ),
        url=summary.content_urls.desktop.page,
    )
