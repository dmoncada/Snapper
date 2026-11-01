from app.api.models import AlbumCandidate
from app.providers.discogs.catalog import DiscogsCatalog
from app.providers.discogs.models import (
    ReleaseRequest,
    ReleaseResponse,
    SearchRequest,
)


async def search_candidates(
    request: SearchRequest,
    discogs: DiscogsCatalog,
) -> list[AlbumCandidate]:
    response = await discogs.search(request)

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


async def get_release(
    album_id: int,
    discogs: DiscogsCatalog,
) -> ReleaseResponse:
    request = ReleaseRequest(release_id=album_id)
    return await discogs.get_release(request)


def release_artist(release: ReleaseResponse) -> str:
    first = release.artists[0]
    return first.anv or first.name


async def get_album(
    album_id: int,
    discogs: DiscogsCatalog,
) -> AlbumCandidate:
    release = await get_release(album_id, discogs)

    primary_image = next(
        (image for image in release.images if image.type == "primary"),
        release.images[0] if release.images else None,
    )

    return AlbumCandidate(
        id=release.id,
        title=release.title,
        artist=release.artists[0].name,
        discogs_url=release.uri,
        thumbnail_url=primary_image.uri150 if primary_image else None,
        cover_image_url=primary_image.uri if primary_image else None,
        country=release.country,
        country_info=release.country_info,
        year=release.year,
        format=[item.name for item in release.formats],
        label=[item.name for item in release.labels],
        genre=release.genres,
    )
