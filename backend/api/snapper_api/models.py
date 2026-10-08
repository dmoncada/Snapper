from typing import Literal

from pydantic import BaseModel, Field


class AlbumCandidate(BaseModel):
    id: int
    artist: str
    title: str
    year: int | None
    formats: list[str]
    labels: list[str]
    country: str | None
    thumbnailUrl: str | None
    coverImageUrl: str | None
    discogsUrl: str | None


class AlbumTrack(BaseModel):
    id: str
    position: str | None
    title: str
    duration: str | None
    previewUrl: str | None


class TracklistRequest(BaseModel):
    discogsReleaseId: int = Field(gt=0)
    artist: str = Field(min_length=1, max_length=200)
    title: str = Field(min_length=1, max_length=200)


class TracklistResponse(BaseModel):
    source: Literal["itunes", "discogs"]
    itunesUrl: str | None
    tracks: list[AlbumTrack]
