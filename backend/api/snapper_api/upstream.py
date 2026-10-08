import logging

import httpx

from .cache import UpstreamPacer

logger = logging.getLogger(__name__)


class UpstreamError(Exception):
    def __init__(self, provider: str, status_code: int | None = None):
        self.provider = provider
        self.status_code = status_code
        super().__init__(f"{provider} request failed")


async def get_json(
    client: httpx.AsyncClient,
    pacer: UpstreamPacer,
    provider: str,
    url: str,
    *,
    params: dict | None = None,
    headers: dict[str, str] | None = None,
) -> dict:
    try:
        await pacer.wait()
        response = await client.get(url, params=params, headers=headers)
        response.raise_for_status()
        payload = response.json()
        if not isinstance(payload, dict):
            raise ValueError("unexpected response")
        return payload
    except (httpx.HTTPError, ValueError) as error:
        status = (
            error.response.status_code
            if isinstance(error, httpx.HTTPStatusError)
            else None
        )
        logger.warning(
            "%s upstream request failed: status=%s type=%s",
            provider,
            status,
            type(error).__name__,
        )
        raise UpstreamError(provider, status) from error
