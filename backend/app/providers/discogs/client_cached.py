from redis_fastapi import CacheBackend

from app.core.cache import DAY, MIN, catalog_cache_key
from app.providers.discogs.catalog import DiscogsCatalog
from app.providers.discogs.client import DiscogsClient
from app.providers.discogs.models import (
    ReleaseRequest,
    ReleaseResponse,
    SearchRequest,
    SearchResponse,
)


class CachedDiscogsClient(DiscogsCatalog):
    def __init__(self, client: DiscogsClient, cache: CacheBackend) -> None:
        self._client = client
        self._cache = cache

    async def search(self, request: SearchRequest) -> SearchResponse:
        key = catalog_cache_key("discogs:search", request)
        if (cached := await self._cache.get(key)) is not None:
            return SearchResponse.model_validate(cached)
        response = await self._client.search(request)
        response_json = SearchResponse.model_dump(response, mode="json")
        await self._cache.set(key, response_json, ttl=15 * MIN)
        return response

    async def get_release(self, request: ReleaseRequest) -> ReleaseResponse:
        key = catalog_cache_key("discogs:release", request)
        if (cached := await self._cache.get(key)) is not None:
            return ReleaseResponse.model_validate(cached)
        response = await self._client.get_release(request)
        response_json = ReleaseResponse.model_dump(response, mode="json")
        await self._cache.set(key, response_json, ttl=1 * DAY)
        return response
