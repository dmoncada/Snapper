from typing import Protocol

from app.providers.itunes.models import (
    LookupRequest,
    LookupResponse,
    SearchRequest,
    SearchResponse,
)


class ItunesCatalog(Protocol):
    async def search(self, request: SearchRequest) -> SearchResponse: ...
    async def lookup(self, request: LookupRequest) -> LookupResponse: ...
