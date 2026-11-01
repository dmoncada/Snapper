from typing import Protocol

from app.providers.discogs.models import (
    ReleaseRequest,
    ReleaseResponse,
    SearchRequest,
    SearchResponse,
)


class DiscogsCatalog(Protocol):
    async def search(self, request: SearchRequest) -> SearchResponse: ...
    async def get_release(self, request: ReleaseRequest) -> ReleaseResponse: ...
