from typing import Annotated, Self

from pydantic import BaseModel, Field, PositiveInt, StringConstraints, model_validator

from app.core.country import Country

NonEmptyStr = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]


class AlbumSearchRequest(BaseModel):
    term: NonEmptyStr | None = None
    barcode: NonEmptyStr | None = None
    limit: int = Field(default=10, ge=1, le=100)

    @model_validator(mode="after")
    def require_search_value(self) -> Self:
        if self.term is None and self.barcode is None:
            raise ValueError("Provide term or barcode")
        return self


class AlbumCandidate(BaseModel):
    id: int
    title: str
    artist: str
    discogs_url: str | None = None
    thumbnail_url: str | None = None
    cover_image_url: str | None = None
    country: str | None = None
    country_info: Country | None = None
    year: int | None = None
    format: list[str] = Field(default_factory=list)
    label: list[str] = Field(default_factory=list)
    genre: list[str] = Field(default_factory=list)
    barcode: list[str] = Field(default_factory=list)


class TracklistRequest(BaseModel):
    discogs_id: PositiveInt
    album_title: NonEmptyStr
    album_artist: NonEmptyStr
    barcode: NonEmptyStr | None = None


class TracklistTrack(BaseModel):
    id: int | None = None
    title: str
    position: str
    duration: str
    preview_url: str | None = None
