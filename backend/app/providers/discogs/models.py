from __future__ import annotations

from typing import Any, Literal

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    PositiveInt,
    model_validator,
)

from app.core.country import Country, normalize_country


class DiscogsModel(BaseModel):
    """Base class for API response models."""

    model_config = ConfigDict(
        extra="ignore",
        populate_by_name=True,
    )


class PaginationUrls(DiscogsModel):
    first: str | None = None
    last: str | None = None
    next: str | None = None
    prev: str | None = None


class Pagination(DiscogsModel):
    page: int
    pages: int
    per_page: int
    items: int
    urls: PaginationUrls | None = None


class ReleaseRequest(BaseModel):
    """Parameters for GET /releases/{release_id}."""

    release_id: PositiveInt
    curr_abbr: str | None = None


SearchType = Literal["release", "master", "artist", "label"]


class SearchRequest(BaseModel):
    """Parameters for GET /database/search."""

    q: str | None = None
    type_: SearchType | None = Field(default=None, alias="type")
    title: str | None = None
    release_title: str | None = None
    credit: str | None = None
    artist: str | None = None
    anv: str | None = None
    label: str | None = None
    genre: str | None = None
    style: str | None = None
    country: str | None = None
    year: str | None = None
    format: str | None = None
    catno: str | None = None
    barcode: str | None = None
    track: str | None = None
    submitter: str | None = None
    contributor: str | None = None
    page: PositiveInt = 1
    per_page: PositiveInt = Field(default=50, le=100)


class Artist(DiscogsModel):
    id: int | None = None
    name: str
    anv: str | None = None
    join: str | None = None
    role: str | None = None
    tracks: str | None = None
    resource_url: str | None = None
    anv_resource_url: str | None = None


class Label(DiscogsModel):
    id: int | None = None
    name: str
    catno: str | None = None
    entity_type: str | None = None
    resource_url: str | None = None


class Format(DiscogsModel):
    name: str
    qty: str | None = None
    descriptions: list[str] = Field(default_factory=list)


class Identifier(DiscogsModel):
    type: str | None = None
    value: str | None = None
    description: str | None = None


class Image(DiscogsModel):
    type: str | None = None
    uri: str | None = None
    resource_url: str | None = None
    uri150: str | None = None
    width: int | None = None
    height: int | None = None


class Track(DiscogsModel):
    position: str | None = None
    type_: str | None = Field(default=None, alias="type_")
    title: str
    duration: str | None = None
    artists: list[Artist] = Field(default_factory=list)
    extraartists: list[Artist] = Field(default_factory=list)


class ReleaseResponse(DiscogsModel):
    id: int
    title: str
    resource_url: str | None = None
    uri: str | None = None
    status: str | None = None
    year: int | None = None
    country: str | None = None
    country_info: Country | None = None
    released: str | None = None
    released_formatted: str | None = None
    notes: str | None = None
    data_quality: str | None = None
    master_id: int | None = None
    master_url: str | None = None

    artists: list[Artist] = Field(default_factory=list)
    extraartists: list[Artist] = Field(default_factory=list)
    labels: list[Label] = Field(default_factory=list)
    formats: list[Format] = Field(default_factory=list)
    tracklist: list[Track] = Field(default_factory=list)
    identifiers: list[Identifier] = Field(default_factory=list)
    images: list[Image] = Field(default_factory=list)

    genres: list[str] = Field(default_factory=list)
    styles: list[str] = Field(default_factory=list)

    # # Discogs returns additional nested data such as community, companies,
    # # videos, and series. Keep these available without over-modeling them.
    # community: dict[str, Any] | None = None
    # companies: list[dict[str, Any]] = Field(default_factory=list)
    # series: list[dict[str, Any]] = Field(default_factory=list)
    # videos: list[dict[str, Any]] = Field(default_factory=list)

    @model_validator(mode="before")
    @classmethod
    def add_country_info(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data

        data = dict(data)
        if data.get("country_info") is None:
            data["country_info"] = normalize_country(data.get("country"))

        return data


class SearchResult(DiscogsModel):
    id: int
    type: str | None = None
    title: str
    resource_url: str | None = None
    uri: str | None = None
    thumb: str | None = None
    cover_image: str | None = None
    master_id: int | None = None
    master_url: str | None = None
    country: str | None = None
    country_info: Country | None = None
    year: int | None = None
    format: list[str] = Field(default_factory=list)
    label: list[str] = Field(default_factory=list)
    genre: list[str] = Field(default_factory=list)
    style: list[str] = Field(default_factory=list)
    catno: str | None = None
    barcode: list[str] = Field(default_factory=list)

    @model_validator(mode="before")
    @classmethod
    def add_country_info(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data

        data = dict(data)
        if data.get("country_info") is None:
            data["country_info"] = normalize_country(data.get("country"))

        return data


class SearchResponse(DiscogsModel):
    pagination: Pagination
    results: list[SearchResult] = Field(default_factory=list)
