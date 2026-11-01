from typing import Annotated

from fastapi import APIRouter, Path, Query
from redis_fastapi import CacheBackendDep

from app.api.deps import DiscogsClientDep, ItunesClientDep
from app.api.handlers.albums import get_album, search_candidates
from app.api.handlers.tracks import resolve_tracks
from app.api.models import (
    AlbumCandidate,
    AlbumSearchRequest,
    NonEmptyStr,
    TracklistResponse,
)
from app.providers.discogs.models import SearchRequest

router = APIRouter(prefix="/albums", tags=["albums"])


@router.get("")
async def search_albums(
    params: Annotated[AlbumSearchRequest, Query()],
    discogs: DiscogsClientDep,
) -> list[AlbumCandidate]:
    request = SearchRequest.model_validate(
        {
            "q": params.term,
            "barcode": params.barcode,
            "per_page": params.limit,
            "type": "release",
        }
    )

    return await search_candidates(request, discogs)


@router.get("/{id}")
async def get_album_by_id(
    id: Annotated[int, Path(gt=0)],
    discogs: DiscogsClientDep,
) -> AlbumCandidate:
    return await get_album(id, discogs)


@router.get("/{id}/tracks")
async def get_tracks(
    id: Annotated[int, Path(gt=0)],
    discogs: DiscogsClientDep,
    itunes: ItunesClientDep,
    cache: CacheBackendDep,
    barcode: Annotated[NonEmptyStr | None, Query()] = None,
) -> TracklistResponse:
    return await resolve_tracks(id, barcode, discogs, itunes, cache)
