from typing import Annotated

import httpx2
from fastapi import APIRouter, Query
from pydantic import ValidationError

from app.api.deps import DiscogsClientDep, ItunesClientDep
from app.api.models import TracklistRequest, TracklistTrack
from app.core.matching import (
    best_matching_album,
    best_matching_artist,
    matching_itunes_tracks,
    matching_upc_tracks,
    normalize_barcode,
)
from app.providers.discogs.client import DiscogsClient
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

TracklistResponse = list[TracklistTrack]

_LOOKUP_ERRORS = (httpx2.HTTPError, ValidationError)


@router.get("/", response_model=TracklistResponse)
async def resolve_tracks(
    params: Annotated[TracklistRequest, Query()],
    discogs: DiscogsClientDep,
    itunes: ItunesClientDep,
) -> TracklistResponse:
    discogs_release = await _get_tracks_by_release_id(discogs, params.discogs_id)
    discogs_tracks = [
        track
        for track in discogs_release.tracklist
        if track.title.strip() and track.type_ in (None, "track")
    ]
    if not discogs_tracks:
        return []

    tracks = await _resolve_by_upc(itunes, params, discogs_tracks)
    if tracks:
        return _itunes_tracklist(tracks)

    tracks = await _resolve_by_album_search(itunes, params, discogs_tracks)
    if tracks:
        return _itunes_tracklist(tracks)

    tracks = await _resolve_by_artist_search(itunes, params, discogs_tracks)
    if tracks:
        return _itunes_tracklist(tracks)

    return _discogs_tracklist(discogs_tracks)


async def _resolve_by_upc(
    itunes: ItunesClient,
    params: TracklistRequest,
    discogs_tracks: list[Track],
) -> list[MusicItem]:
    barcode = normalize_barcode(params.barcode)
    if barcode is None:
        return []

    try:
        lookup = await _get_tracks_by_upc(itunes, barcode)
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
    params: TracklistRequest,
    discogs_tracks: list[Track],
) -> list[MusicItem]:
    try:
        term = f"{params.album_artist} {params.album_title}"
        search = await _search_albums_by_term(itunes, term)
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

    return await _get_matching_album_tracks(itunes, album.collectionId, discogs_tracks)


async def _resolve_by_artist_search(
    itunes: ItunesClient,
    params: TracklistRequest,
    discogs_tracks: list[Track],
) -> list[MusicItem]:
    try:
        search = await _search_artist_id_by_term(itunes, params.album_artist)
    except _LOOKUP_ERRORS:
        return []

    artist = best_matching_artist(search.results, params.album_artist)
    if artist is None or artist.artistId is None:
        return []

    try:
        albums = await _get_albums_by_artist_id(itunes, artist.artistId)
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

    return await _get_matching_album_tracks(itunes, album.collectionId, discogs_tracks)


async def _get_matching_album_tracks(
    itunes: ItunesClient,
    album_id: int,
    discogs_tracks: list[Track],
) -> list[MusicItem]:
    try:
        lookup = await _get_tracks_by_album_id(itunes, album_id)
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


async def _get_tracks_by_upc(itunes: ItunesClient, barcode: str) -> LookupResponse:
    return await itunes.lookup(LookupRequest(upc=barcode, entity="song"))


async def _search_albums_by_term(itunes: ItunesClient, term: str) -> SearchResponse:
    return await itunes.search(SearchRequest(term=term, entity="album"))


async def _search_artist_id_by_term(
    itunes: ItunesClient, artist: str
) -> SearchResponse:
    return await itunes.search(SearchRequest(term=artist, entity="musicArtist"))


async def _get_albums_by_artist_id(
    itunes: ItunesClient, artist_id: int
) -> LookupResponse:
    return await itunes.lookup(LookupRequest(ids=[artist_id], entity="album"))


async def _get_tracks_by_album_id(
    itunes: ItunesClient, album_id: int
) -> LookupResponse:
    return await itunes.lookup(LookupRequest(ids=[album_id], entity="song"))


async def _get_tracks_by_release_id(
    discogs: DiscogsClient, release_id: int
) -> ReleaseResponse:
    return await discogs.get_release(ReleaseRequest(release_id=release_id))
