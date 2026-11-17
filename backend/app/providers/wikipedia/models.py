"""Only the fields needed from Wikipedia search and page summaries."""

from pydantic import BaseModel, Field


class SearchPage(BaseModel):
    key: str
    title: str
    description: str | None = None


class SearchResponse(BaseModel):
    pages: list[SearchPage] = Field(default_factory=list)


class SummaryDesktopUrls(BaseModel):
    page: str


class SummaryContentUrls(BaseModel):
    desktop: SummaryDesktopUrls


class PageSummary(BaseModel):
    title: str
    extract: str | None = None
    extract_html: str | None = None
    type: str | None = None
    content_urls: SummaryContentUrls
