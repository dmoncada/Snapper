from typing import Annotated

from fastapi import APIRouter, Query

from app.api.deps import DiscogsClientDep
from app.api.models import AlbumCandidate, AlbumSearchRequest
from app.providers.discogs.models import SearchRequest

router = APIRouter(prefix="/albums", tags=["albums"])


@router.get("/", response_model=list[AlbumCandidate])
async def search_candidates(
    params: Annotated[AlbumSearchRequest, Query()],
    discogs: DiscogsClientDep,
) -> list[AlbumCandidate]:
    response = await discogs.search(
        SearchRequest.model_validate(
            {
                "q": params.term,
                "barcode": params.barcode,
                "per_page": params.limit,
                "type": "release",
            }
        )
    )

    albums = []
    for result in response.results:
        artist, separator, title = result.title.partition(" - ")

        albums.append(
            AlbumCandidate(
                discogs_id=result.id,
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
