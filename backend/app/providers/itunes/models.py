from __future__ import annotations

from typing import Annotated, Any, Literal

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    StringConstraints,
    field_validator,
)

MusicEntity = Literal["musicArtist", "album", "song"]
LookupEntity = Literal["album", "song"]
SearchAttribute = Literal["artistTerm", "albumTerm", "songTerm"]


class ItunesModel(BaseModel):
    model_config = ConfigDict(extra="ignore")


CountryCode = Annotated[
    str,
    StringConstraints(
        min_length=2,
        max_length=2,
        pattern=r"^[A-Za-z]{2}$",
    ),
]


class SearchRequest(ItunesModel):
    term: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]
    country: CountryCode = "US"
    entity: MusicEntity = "song"
    attribute: SearchAttribute | None = None
    limit: int = Field(default=50, ge=1, le=200)
    lang: Literal["en_us", "ja_jp"] = "en_us"
    version: Literal[1, 2] = 2
    explicit: Literal["Yes", "No"] = "Yes"

    @field_validator("country")
    @classmethod
    def uppercase_country(cls, value: str) -> str:
        return value.upper()


class LookupRequest(ItunesModel):
    """Look up catalog items by iTunes IDs or an album UPC.

    Provide exactly one lookup key. Multiple IDs may be supplied for
    the same key. `entity` optionally expands artist lookups to albums
    or songs, or album lookups to songs.
    """

    ids: list[int] | None = Field(default=None, min_length=1, max_length=200)
    upc: (
        Annotated[
            str,
            StringConstraints(strip_whitespace=True, min_length=8, max_length=14),
        ]
        | None
    ) = None
    entity: LookupEntity | None = None
    limit: int | None = Field(default=None, ge=1, le=200)
    country: CountryCode = "US"

    @field_validator("country")
    @classmethod
    def uppercase_country(cls, value: str) -> str:
        return value.upper()

    @field_validator("ids")
    @classmethod
    def validate_ids(cls, value: list[int] | None) -> list[int] | None:
        if value is not None and any(item <= 0 for item in value):
            raise ValueError("iTunes IDs must be positive integers")
        if value is not None and len(set(value)) != len(value):
            raise ValueError("iTunes IDs must be unique")
        return value

    def to_params(self) -> dict[str, Any]:
        if (self.ids is None) == (self.upc is None):
            raise ValueError("Provide exactly one of ids or upc")

        params: dict[str, Any] = {"country": self.country}

        if self.ids is None:
            params["upc"] = self.upc
        else:
            params["id"] = ",".join(str(item) for item in self.ids)

        if self.entity is not None:
            params["entity"] = self.entity

        if self.limit is not None:
            params["limit"] = self.limit

        return params


class MusicItem(ItunesModel):
    """Normalized subset of Apple's artist, album, and song results."""

    wrapperType: Literal["artist", "collection", "track"] | None = None
    kind: Literal["musicArtist", "album", "song", "music-video"] | None = None

    artistId: int | None = None
    collectionId: int | None = None
    trackId: int | None = None

    artistName: str | None = None
    artistType: str | None = None
    artistLinkUrl: str | None = None
    artistViewUrl: str | None = None

    collectionName: str | None = None
    collectionCensoredName: str | None = None
    collectionViewUrl: str | None = None
    collectionType: str | None = None
    collectionArtistName: str | None = None

    trackName: str | None = None
    trackCensoredName: str | None = None
    trackViewUrl: str | None = None
    trackNumber: int | None = None
    trackCount: int | None = None
    trackTimeMillis: int | None = None

    primaryGenreName: str | None = None
    primaryGenreId: int | None = None
    releaseDate: str | None = None
    country: str | None = None
    currency: str | None = None

    artworkUrl30: str | None = None
    artworkUrl60: str | None = None
    artworkUrl100: str | None = None
    artworkUrl512: str | None = None
    previewUrl: str | None = None

    collectionPrice: float | None = None
    trackPrice: float | None = None
    trackExplicitness: str | None = None
    collectionExplicitness: str | None = None

    discCount: int | None = None
    discNumber: int | None = None
    isStreamable: bool | None = None


class SearchResponse(ItunesModel):
    resultCount: int
    results: list[MusicItem] = Field(default_factory=list)


class LookupResponse(ItunesModel):
    resultCount: int
    results: list[MusicItem] = Field(default_factory=list)
