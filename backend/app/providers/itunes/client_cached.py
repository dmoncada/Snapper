from statistics import mode

from pydantic import ValidationError
from redis_fastapi import CacheBackend

from app.core.cache import DAY, HOUR, catalog_cache_key
from app.providers.itunes.catalog import ItunesCatalog
from app.providers.itunes.client import ItunesClient
from app.providers.itunes.models import (
    LookupRequest,
    LookupResponse,
    SearchRequest,
    SearchResponse,
)


class CachedItunesClient(ItunesCatalog):
    def __init__(self, client: ItunesClient, cache: CacheBackend) -> None:
        self._client = client
        self._cache = cache

    async def search(self, request: SearchRequest) -> SearchResponse:
        key = catalog_cache_key("itunes:search", request)
        if (cached := await self._cache.get(key)) is not None:
            return SearchResponse.model_validate(cached)
        response = await self._client.search(request)
        response_json = SearchResponse.model_dump(response, mode="json")
        await self._cache.set(key, response_json, ttl=6 * HOUR)
        return response

    async def lookup(self, request: LookupRequest) -> LookupResponse:
        key = catalog_cache_key("itunes:lookup", request)
        if (cached := await self._cache.get(key)) is not None:
            return LookupResponse.model_validate(cached)
        response = await self._client.lookup(request)
        response_json = LookupResponse.model_dump(response, mode="json")
        await self._cache.set(key, response_json, ttl=1 * DAY)
        return response
