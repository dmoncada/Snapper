from __future__ import annotations

from collections.abc import Mapping
from typing import Any

import httpx2
from tenacity import (
    retry,
    retry_if_exception,
    stop_after_attempt,
    wait_exponential_jitter,
)

from app.core.rate_limit import RateLimitedAsyncTransport, SlidingWindowRateLimiter
from app.core.retry import is_retryable
from app.providers.itunes.models import (
    LookupRequest,
    LookupResponse,
    SearchRequest,
    SearchResponse,
)

ITUNES_API_BASE_URL = "https://itunes.apple.com"


def create_itunes_http_client(
    *,
    base_url: str = ITUNES_API_BASE_URL,
    max_requests: int = 20,
    rate_limit_period: float = 60.0,
    timeout: float = 20.0,
    max_connections: int = 10,
    max_keepalive_connections: int = 5,
) -> httpx2.AsyncClient:
    """Create a rate-limited HTTP client. The caller owns its lifecycle."""

    transport = RateLimitedAsyncTransport(
        transport=httpx2.AsyncHTTPTransport(
            limits=httpx2.Limits(
                max_connections=max_connections,
                max_keepalive_connections=max_keepalive_connections,
            ),
        ),
        limiter=SlidingWindowRateLimiter(
            max_requests=max_requests,
            period=rate_limit_period,
        ),
    )

    return httpx2.AsyncClient(
        base_url=base_url.rstrip("/") + "/",
        transport=transport,
        timeout=timeout,
        headers={"Accept": "application/json"},
    )


class ItunesClient:
    """Typed async client for music artist, album, and song catalog data."""

    def __init__(self, http_client: httpx2.AsyncClient) -> None:
        self._http = http_client

    @retry(
        retry=retry_if_exception(is_retryable),
        stop=stop_after_attempt(3),
        wait=wait_exponential_jitter(initial=0.5, max=8),
        reraise=True,
    )
    async def _get(
        self,
        path: str,
        params: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        response = await self._http.get(path, params=params)
        response.raise_for_status()
        return response.json()

    async def search(self, request: SearchRequest) -> SearchResponse:
        params = request.model_dump(exclude_none=True)
        data = await self._get("search", params)
        return SearchResponse.model_validate(data)

    async def lookup(self, request: LookupRequest) -> LookupResponse:
        params = request.to_params()
        data = await self._get("lookup", params)
        return LookupResponse.model_validate(data)
