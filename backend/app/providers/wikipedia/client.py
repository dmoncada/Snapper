"""Small async client for the English Wikipedia read APIs."""

from urllib.parse import quote

import httpx2

from app.providers.wikipedia.models import PageSummary, SearchResponse

WIKIPEDIA_API_BASE_URL = "https://en.wikipedia.org/"


def create_wikipedia_http_client() -> httpx2.AsyncClient:
    return httpx2.AsyncClient(
        base_url=WIKIPEDIA_API_BASE_URL,
        timeout=10.0,
        headers={
            "User-Agent": "Snapper/0.1 (https://github.com/dmoncada/Snapper)",
            "Accept": "application/json",
        },
    )


class WikipediaClient:
    def __init__(self, http_client: httpx2.AsyncClient) -> None:
        self._http = http_client

    async def search(self, query: str) -> SearchResponse:
        response = await self._http.get(
            "w/rest.php/v1/search/page",
            params={"q": query, "limit": 10},
        )

        response.raise_for_status()
        return SearchResponse.model_validate(response.json())

    async def summary(self, page_key: str) -> PageSummary | None:
        response = await self._http.get(
            f"api/rest_v1/page/summary/{quote(page_key, safe='')}"
        )
        if response.status_code == 404:
            return None

        response.raise_for_status()
        return PageSummary.model_validate(response.json())
