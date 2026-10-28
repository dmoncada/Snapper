import logging
from typing import Annotated

import httpx2
from fastapi import APIRouter, Query
from pydantic import ValidationError
from redis_fastapi import CacheBackend, CacheBackendDep

from app.api.deps import DiscogsClientDep, ItunesClientDep
from app.api.models import TracklistRequest, TracklistResponse, TracklistTrack
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


class ResolvedAlbum(list[MusicItem]):
    def __init__(
        self,
        album: MusicItem | None = None,
        tracks: list[MusicItem] | None = None,
    ):
        super().__init__(tracks or [])
        self.album = album


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
        return TracklistResponse()

    audio_tracks, _ = _split_cd_dvd_tracks(discogs_release, discogs_tracks)

    artist_params = [params]

    if len(discogs_release.artists) == 1:
        canonical_artist = discogs_release.artists[0].name.strip()

        left = normalize_name(canonical_artist)
        right = normalize_name(params.album_artist)

        if canonical_artist and left != right:
            update = {"album_artist": canonical_artist}
            copy = params.model_copy(update=update)
            artist_params.insert(0, copy)

    for resolver in (
        _resolve_by_upc,
        _resolve_by_album_search,
        _resolve_by_artist_search,
    ):
        for candidate_params in artist_params:
            resolved = await resolver(itunes, cache, candidate_params, audio_tracks)
            if resolved:
                album = resolved.album
                album_url = album.collectionViewUrl if album is not None else None
                album_tracks = _itunes_tracklist(resolved)
                return TracklistResponse(album_url=album_url, tracks=album_tracks)

    logger.error(
        "iTunes could not resolve tracks for Discogs release %s (%s by %s; barcode: %s)",
        params.discogs_id,
        params.album_title,
        params.album_artist,
        params.barcode,
    )

    return TracklistResponse(tracks=_discogs_tracklist(discogs_tracks))


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
) -> ResolvedAlbum:
    barcode = normalize_barcode(params.barcode)
    if barcode is None:
        return ResolvedAlbum()

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
        return ResolvedAlbum()

    tracks = matching_upc_tracks(
        lookup.results,
        params.album_artist,
        params.album_title,
        discogs_tracks,
    )
    if not tracks:
        return ResolvedAlbum()

    album = next(
        (
            item
            for item in lookup.results
            if item.wrapperType == "collection"
            and item.collectionId == tracks[0].collectionId
        ),
        None,
    )

    return ResolvedAlbum(album, tracks)


async def _resolve_by_album_search(
    itunes: ItunesClient,
    cache: CacheBackend,
    params: TracklistRequest,
    discogs_tracks: list[Track],
) -> ResolvedAlbum:
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
        return ResolvedAlbum()

    album = best_matching_album(
        search.results,
        params.album_artist,
        params.album_title,
        len(discogs_tracks),
    )

    if album is not None and album.collectionId is not None:
        tracks = await _get_matching_album_tracks(
            itunes, cache, album.collectionId, discogs_tracks
        )
        if tracks:
            return ResolvedAlbum(album, tracks)

    # A physical release may have a long subtitle while its digital album does not.
    # Require the same artist, opening title word, and track count before looking
    # up an alternative collection; ordered track titles remain the final check.
    if len(discogs_tracks) < 3:
        return ResolvedAlbum()

    title_words = normalize_name(params.album_title).split()
    if not title_words:
        return ResolvedAlbum()

    title_start = title_words[0]
    artist_name = normalize_name(params.album_artist)

    for candidate in search.results:
        if (
            candidate.wrapperType != "collection"
            or candidate.collectionId is None
            or candidate.collectionId == (album.collectionId if album else None)
            or candidate.trackCount != len(discogs_tracks)
            or normalize_name(candidate.artistName) != artist_name
            or normalize_name(candidate.collectionName).split()[:1] != [title_start]
        ):
            continue

        tracks = await _get_matching_album_tracks(
            itunes, cache, candidate.collectionId, discogs_tracks
        )
        if tracks:
            return ResolvedAlbum(candidate, tracks)

    return ResolvedAlbum()


async def _resolve_by_artist_search(
    itunes: ItunesClient,
    cache: CacheBackend,
    params: TracklistRequest,
    discogs_tracks: list[Track],
) -> ResolvedAlbum:
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
            return ResolvedAlbum()

        artist = best_matching_artist(search.results, params.album_artist)
        if artist is None or artist.artistId is None:
            return ResolvedAlbum()

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
        return ResolvedAlbum()

    album = best_matching_album(
        albums.results,
        params.album_artist,
        params.album_title,
        len(discogs_tracks),
    )

    if album is None or album.collectionId is None:
        return ResolvedAlbum()

    tracks = await _get_matching_album_tracks(
        itunes, cache, album.collectionId, discogs_tracks
    )

    if tracks and not cache_hit:
        await cache.set(artist_key, artist_id, ttl=7 * DAY)

    return ResolvedAlbum(album, tracks) if tracks else ResolvedAlbum()


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


def _split_cd_dvd_tracks(
    release: ReleaseResponse, tracks: list[Track]
) -> tuple[list[Track], list[Track]]:
    cd_formats = [item for item in release.formats if item.name.casefold() == "cd"]
    if (
        len(cd_formats) != 1
        or cd_formats[0].qty != "1"
        or not any(item.name.casefold() == "dvd" for item in release.formats)
        or not tracks[0].position
    ):
        return tracks, []

    first_position = tracks[0].position.strip()
    for index, track in enumerate(tracks[1:], start=1):
        if track.position and track.position.strip() == first_position:
            return tracks[:index], tracks[index:]

    return tracks, []


def _itunes_tracklist(tracks: list[MusicItem]) -> list[TracklistTrack]:
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


def _discogs_tracklist(tracks: list[Track]) -> list[TracklistTrack]:
    return [
        TracklistTrack(
            title=track.title,
            position=track.position or str(index),
            duration=track.duration or "",
        )
        for index, track in enumerate(tracks, start=1)
    ]
