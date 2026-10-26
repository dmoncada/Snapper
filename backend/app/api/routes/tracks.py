import logging
from typing import Annotated

import httpx2
from fastapi import APIRouter, Query
from pydantic import ValidationError
from redis_fastapi import CacheBackend, CacheBackendDep

from app.api.deps import DiscogsClientDep, ItunesClientDep
from app.api.models import TracklistRequest, TracklistTrack
from app.core.cache import DAY, HOUR, MIN, cached_provider_call, catalog_cache_key
from app.core.matching import (
    best_matching_album,
    best_matching_artist,
    matching_itunes_tracks,
    matching_upc_tracks,
    normalize_barcode,
    normalize_name,
)
from app.providers.discogs.models import ReleaseRequest, ReleaseResponse, Track
from app.providers.itunes.client import ItunesClient
from app.providers.itunes.models import (
    LookupRequest,
    LookupResponse,
    MusicItem,
    SearchRequest,
    SearchResponse,
)

router = APIRouter(prefix="/tracks", tags=["tracks"])
logger: logging.Logger = logging.getLogger(__name__)

TracklistResponse = list[TracklistTrack]

_LOOKUP_ERRORS = (httpx2.HTTPError, ValidationError)


@router.get("/", response_model=TracklistResponse)
async def resolve_tracks(
    params: Annotated[TracklistRequest, Query()],
    discogs: DiscogsClientDep,
    itunes: ItunesClientDep,
    cache: CacheBackendDep,
) -> TracklistResponse:
    release_request = ReleaseRequest(release_id=params.discogs_id)
    discogs_release = await cached_provider_call(
        cache,
        namespace="discogs:release",
        request=release_request,
        response_model=ReleaseResponse,
        fetch=lambda: discogs.get_release(release_request),
        ttl=DAY,
    )
    discogs_tracks = [
        track
        for track in discogs_release.tracklist
        if track.title.strip() and track.type_ in (None, "track")
    ]
    if not discogs_tracks:
        return []

    tracks = await _resolve_by_upc(itunes, cache, params, discogs_tracks)
    if tracks:
        return _itunes_tracklist(tracks)

    tracks = await _resolve_by_album_search(itunes, cache, params, discogs_tracks)
    if tracks:
        return _itunes_tracklist(tracks)

    tracks = await _resolve_by_artist_search(itunes, cache, params, discogs_tracks)
    if tracks:
        return _itunes_tracklist(tracks)

    logger.error(
        "iTunes could not resolve tracks for Discogs release %s (%s by %s; barcode: %s)",
        params.discogs_id,
        params.album_title,
        params.album_artist,
        params.barcode,
    )

    return _discogs_tracklist(discogs_tracks)


def _artist_id_cache_key(artist_name: str, country: str = "US") -> str:
    request = SearchRequest(
        term=normalize_name(artist_name),
        entity="musicArtist",
        country=country,
    )
    return catalog_cache_key("itunes:artist-id", request)


async def _resolve_by_upc(
    itunes: ItunesClient,
    cache: CacheBackend,
    params: TracklistRequest,
    discogs_tracks: list[Track],
) -> list[MusicItem]:
    barcode = normalize_barcode(params.barcode)
    if barcode is None:
        return []

    try:
        request = LookupRequest(upc=barcode, entity="song")
        lookup = await cached_provider_call(
            cache,
            namespace="itunes:lookup",
            request=request,
            response_model=LookupResponse,
            fetch=lambda: itunes.lookup(request),
            ttl=DAY,
            empty_ttl=5 * MIN,
        )
    except _LOOKUP_ERRORS:
        return []

    return matching_upc_tracks(
        lookup.results,
        params.album_artist,
        params.album_title,
        discogs_tracks,
    )


async def _resolve_by_album_search(
    itunes: ItunesClient,
    cache: CacheBackend,
    params: TracklistRequest,
    discogs_tracks: list[Track],
) -> list[MusicItem]:
    try:
        term = f"{params.album_artist} {params.album_title}"
        request = SearchRequest(term=term, entity="album")
        search = await cached_provider_call(
            cache,
            namespace="itunes:search",
            request=request,
            response_model=SearchResponse,
            fetch=lambda: itunes.search(request),
            ttl=6 * HOUR,
            empty_ttl=5 * MIN,
        )
    except _LOOKUP_ERRORS:
        return []

    album = best_matching_album(
        search.results,
        params.album_artist,
        params.album_title,
        len(discogs_tracks),
    )

    if album is None or album.collectionId is None:
        return []

    return await _get_matching_album_tracks(
        itunes, cache, album.collectionId, discogs_tracks
    )


async def _resolve_by_artist_search(
    itunes: ItunesClient,
    cache: CacheBackend,
    params: TracklistRequest,
    discogs_tracks: list[Track],
) -> list[MusicItem]:
    artist_key = _artist_id_cache_key(params.album_artist)

    cached_artist_id = await cache.get(artist_key)

    cache_hit = isinstance(cached_artist_id, int) and cached_artist_id > 0
    artist_id = cached_artist_id if cache_hit else None
    if artist_id is None:
        try:
            search_request = SearchRequest(
                term=params.album_artist, entity="musicArtist"
            )
            search = await cached_provider_call(
                cache,
                namespace="itunes:search",
                request=search_request,
                response_model=SearchResponse,
                fetch=lambda: itunes.search(search_request),
                ttl=6 * HOUR,
                empty_ttl=5 * MIN,
            )
        except _LOOKUP_ERRORS:
            return []

        artist = best_matching_artist(search.results, params.album_artist)
        if artist is None or artist.artistId is None:
            return []

        artist_id = artist.artistId

    try:
        albums_request = LookupRequest(ids=[artist_id], entity="album")
        albums = await cached_provider_call(
            cache,
            namespace="itunes:lookup",
            request=albums_request,
            response_model=LookupResponse,
            fetch=lambda: itunes.lookup(albums_request),
            ttl=6 * HOUR,
            empty_ttl=5 * MIN,
        )
    except _LOOKUP_ERRORS:
        return []

    album = best_matching_album(
        albums.results,
        params.album_artist,
        params.album_title,
        len(discogs_tracks),
    )

    if album is None or album.collectionId is None:
        return []

    tracks = await _get_matching_album_tracks(
        itunes, cache, album.collectionId, discogs_tracks
    )

    if tracks and not cache_hit:
        await cache.set(artist_key, artist_id, ttl=7 * DAY)

    return tracks


async def _get_matching_album_tracks(
    itunes: ItunesClient,
    cache: CacheBackend,
    album_id: int,
    discogs_tracks: list[Track],
) -> list[MusicItem]:
    try:
        request = LookupRequest(ids=[album_id], entity="song")
        lookup = await cached_provider_call(
            cache,
            namespace="itunes:lookup",
            request=request,
            response_model=LookupResponse,
            fetch=lambda: itunes.lookup(request),
            ttl=DAY,
            empty_ttl=5 * MIN,
        )
    except _LOOKUP_ERRORS:
        return []

    return matching_itunes_tracks(lookup.results, album_id, discogs_tracks)


def _itunes_tracklist(tracks: list[MusicItem]) -> TracklistResponse:
    return [
        TracklistTrack(
            id=track.trackId,
            title=track.trackName or "",
            position=f"{track.discNumber or 1}-{track.trackNumber}",
            duration=(
                f"{track.trackTimeMillis // 60_000}:"
                f"{track.trackTimeMillis // 1_000 % 60:02}"
                if track.trackTimeMillis is not None
                else ""
            ),
            preview_url=track.previewUrl,
        )
        for track in tracks
    ]


def _discogs_tracklist(tracks: list[Track]) -> TracklistResponse:
    return [
        TracklistTrack(
            title=track.title,
            position=track.position or str(index),
            duration=track.duration or "",
        )
        for index, track in enumerate(tracks, start=1)
    ]
