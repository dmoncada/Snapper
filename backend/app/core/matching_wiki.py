"""Conservative Wikipedia article selection for a Discogs release."""

from app.core.matching import normalize_name
from app.providers.wikipedia.models import SearchPage

_MUSICIAN_TERMS = (
    "band",
    "composer",
    "dj",
    "ensemble",
    "musician",
    "orchestra",
    "rapper",
    "record producer",
    "singer",
    "vocalist",
    "musical group",
)


def _title_key(title: str) -> str:
    # Wikipedia often adds a parenthetical disambiguator to the article title.
    return normalize_name(title.partition(" (")[0])


def _contains_phrase(text: str, phrase: str) -> bool:
    return f" {normalize_name(phrase)} " in f" {normalize_name(text)} "


def select_artist_page(pages: list[SearchPage], artist_name: str) -> SearchPage | None:
    artist_key = normalize_name(artist_name)
    matches = [
        page
        for page in pages
        if _title_key(page.title) == artist_key
        and page.description
        and any(_contains_phrase(page.description, term) for term in _MUSICIAN_TERMS)
    ]
    return matches[0] if len(matches) == 1 else None


def select_album_page(
    pages: list[SearchPage], album_title: str, artist_name: str
) -> SearchPage | None:
    matches = [
        page
        for page in pages
        if _title_key(page.title) == normalize_name(album_title)
        and page.description
        and _contains_phrase(page.description, "album")
        and _contains_phrase(page.description, artist_name)
    ]
    return matches[0] if len(matches) == 1 else None
