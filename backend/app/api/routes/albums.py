from typing import Annotated

from fastapi import APIRouter, Query
from redis_fastapi import CacheBackendDep

from app.api.deps import DiscogsClientDep
from app.api.models import AlbumCandidate, AlbumSearchRequest
from app.core.cache import MIN, cached_provider_call
from app.providers.discogs.models import SearchRequest, SearchResponse

router = APIRouter(prefix="/albums", tags=["albums"])


@router.get("/", response_model=list[AlbumCandidate])
async def search_candidates(
    params: Annotated[AlbumSearchRequest, Query()],
    discogs: DiscogsClientDep,
    cache: CacheBackendDep,
) -> list[AlbumCandidate]:
    request = SearchRequest.model_validate(
        {
            "q": params.term,
            "barcode": params.barcode,
            "per_page": params.limit,
            "type": "release",
        }
    )

    response = await cached_provider_call(
        cache,
        namespace="discogs:search",
        request=request,
        response_model=SearchResponse,
        fetch=lambda: discogs.search(request),
        ttl=15 * MIN,
        empty_ttl=MIN,
    )

    albums = []
    for result in response.results:
        artist, separator, title = result.title.partition(" - ")

        albums.append(
            AlbumCandidate(
                id=result.id,
                title=title if separator else result.title,
                artist=artist if separator else result.title,
                discogs_url=result.uri,
                thumbnail_url=result.thumb,
                cover_image_url=result.cover_image,
                country=result.country,
                country_info=result.country_info,
                year=result.year,
                format=result.format,
                label=result.label,
                genre=result.genre,
                barcode=result.barcode,
            )
        )

    return albums
