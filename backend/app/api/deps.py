from typing import Annotated

from fastapi import Depends, Request
from redis_fastapi import CacheBackendDep

from app.providers.discogs.catalog import DiscogsCatalog
from app.providers.discogs.client import DiscogsClient
from app.providers.discogs.client_cached import CachedDiscogsClient
from app.providers.itunes.catalog import ItunesCatalog
from app.providers.itunes.client import ItunesClient
from app.providers.itunes.client_cached import CachedItunesClient


def get_discogs_client(request: Request, cache: CacheBackendDep) -> DiscogsCatalog:
    client: DiscogsClient = request.app.state.discogs
    return CachedDiscogsClient(client, cache)


def get_itunes_client(request: Request, cache: CacheBackendDep) -> ItunesCatalog:
    client: ItunesClient = request.app.state.itunes
    return CachedItunesClient(client, cache)


DiscogsClientDep = Annotated[DiscogsCatalog, Depends(get_discogs_client)]
ItunesClientDep = Annotated[ItunesCatalog, Depends(get_itunes_client)]
