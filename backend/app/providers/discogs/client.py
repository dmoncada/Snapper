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
from app.providers.discogs.models import (
    ReleaseRequest,
    ReleaseResponse,
    SearchRequest,
    SearchResponse,
)

DISCOGS_API_BASE_URL = "https://api.discogs.com"


def create_discogs_http_client(
    token: str,
    *,
    user_agent: str = "snapper-backend/0.1",
    base_url: str = DISCOGS_API_BASE_URL,
    max_requests: int = 60,
    rate_limit_period: float = 60.0,
    timeout: float = 20.0,
    max_connections: int = 20,
    max_keepalive_connections: int = 10,
) -> httpx2.AsyncClient:
    """Create a configured HTTP client for the Discogs API.

    The caller owns the returned client and must close it.
    """

    if not token.strip():
        raise ValueError("token must not be empty")
    if not user_agent.strip():
        raise ValueError("user_agent must not be empty")

    transport = RateLimitedAsyncTransport(
        transport=httpx2.AsyncHTTPTransport(
            http2=True,
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
        headers={
            "Authorization": f"Discogs token={token}",
            "User-Agent": user_agent,
            "Accept": "application/json",
        },
    )


class DiscogsClient:
    """Typed Discogs API wrapper around a caller-owned HTTP client."""

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
        *,
        params: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        response = await self._http.get(path, params=params)
        response.raise_for_status()
        return response.json()

    async def search(self, request: SearchRequest) -> SearchResponse:
        params = request.model_dump(by_alias=True, exclude_none=True)
        data = await self._get("database/search", params=params)
        return SearchResponse.model_validate(data)

    async def get_release(self, request: ReleaseRequest) -> ReleaseResponse:
        params = request.model_dump(exclude={"release_id"}, exclude_none=True)
        data = await self._get(f"releases/{request.release_id}", params=params)
        return ReleaseResponse.model_validate(data)
