"""Deterministic matching of Discogs releases to iTunes catalog records."""

import re
import unicodedata
from collections.abc import Sequence

from jarowinkler import jarowinkler_similarity

from app.providers.discogs.models import Track
from app.providers.itunes.models import MusicItem

_EDITION_WORDS = frozenset(
    {"anniversary", "deluxe", "expanded", "live", "remaster", "remastered"}
)


# Punctuation that often varies between metadata providers.
_TRANSLATE = str.maketrans(
    {
        "\u2018": "'",  # left single quotation mark
        "\u2019": "'",  # right single quotation mark
        "\u201a": "'",  # single low-9 quotation mark
        "\u201b": "'",  # single high-reversed-9 quotation mark
        "\u02bc": "'",  # modifier letter apostrophe
        "\u0060": "'",  # grave accent, often used as an apostrophe
        "\u00b4": "'",  # acute accent, often used as an apostrophe
        "\u201c": '"',  # left double quotation mark
        "\u201d": '"',  # right double quotation mark
        "\u201e": '"',  # double low-9 quotation mark
        "\u2013": "-",  # en dash
        "\u2014": "-",  # em dash
        "\u2212": "-",  # mathematical minus
        "\ufe58": "-",  # small em dash
        "\ufe63": "-",  # small hyphen-minus
        "\uff0d": "-",  # fullwidth hyphen-minus
        "\u2026": "...",  # ellipsis
        "\u00a0": " ",  # no-break space
        "\u2007": " ",  # figure space
        "\u202f": " ",  # narrow no-break space
        "\u3000": " ",  # ideographic space
    }
)

# Optional, conservative equivalences for common title typography.
_SYMBOLS = {
    "&": " and ",
    "+": " and ",
    "\u00d7": " x ",  # multiplication sign
}


def normalize_name(value: str | None) -> str:
    """Return a comparison key for an album or artist name.

    Intentionally does not remove edition markers such as 'live',
    'remastered', 'deluxe', 'anniversary', or 'expanded'.
    """
    if value is None:
        return ""

    value = str(value).strip()
    if not value:
        return ""

    # 1. Normalize Unicode compatibility forms:
    #    e.g. fullwidth letters, ligatures, and presentation variants.
    value = unicodedata.normalize("NFKC", value)

    # 2. Standardize common typographic punctuation and spaces.
    value = value.translate(_TRANSLATE)

    # 3. Case-insensitive comparison, including Unicode case folding.
    value = value.casefold()

    # 4. Expand a few symbols used interchangeably in titles.
    for symbol, replacement in _SYMBOLS.items():
        value = value.replace(symbol, replacement)

    # 5. Decompose accented characters and remove combining marks.
    #    This makes many Latin-script accent differences comparable.
    decomposed = unicodedata.normalize("NFKD", value)
    value = "".join(
        ch for ch in decomposed if not unicodedata.category(ch).startswith("M")
    )

    # 6. Remove punctuation and symbols, but preserve letters,
    #    numbers, and spaces. Separators become spaces so words
    #    don't accidentally run together.
    chars = []
    for ch in value:
        category = unicodedata.category(ch)
        if ch.isspace():
            chars.append(" ")
        elif category[0] in {"P", "S"}:
            chars.append(" ")
        else:
            chars.append(ch)
    value = "".join(chars)

    # 7. Collapse whitespace and trim.
    value = re.sub(r"\s+", " ", value).strip()

    return value


def normalize_barcode(value: str | None) -> str | None:
    """Return an iTunes-compatible UPC/EAN, ignoring printed separators."""
    if value is None:
        return None
    digits = "".join(char for char in value if char.isascii() and char.isdigit())
    if 8 <= len(digits) <= 14:
        return digits.zfill(12) if len(digits) < 12 else digits
    return None


def _similarity(left: str, right: str) -> float:
    normalized_left = normalize_name(left)
    normalized_right = normalize_name(right)
    if normalized_left and normalized_right:
        return jarowinkler_similarity(normalized_left, normalized_right)
    return 0.0


def _same_edition(left: str, right: str) -> bool:
    left_words = set(normalize_name(left).split()) & _EDITION_WORDS
    right_words = set(normalize_name(right).split()) & _EDITION_WORDS

    if "remastered" in left_words:
        left_words.remove("remastered")
        left_words.add("remaster")

    if "remastered" in right_words:
        right_words.remove("remastered")
        right_words.add("remaster")

    return left_words == right_words


def best_matching_artist(results: Sequence[MusicItem], artist: str) -> MusicItem | None:
    """Choose a confident artist match, with stable handling of duplicate names."""
    scored = [
        (_similarity(artist, item.artistName), item)
        for item in results
        if item.wrapperType == "artist"
        and item.artistId is not None
        and item.artistId > 0
        and item.artistName
    ]
    scored = [(score, item) for score, item in scored if score >= 0.94]
    scored.sort(key=lambda pair: (-pair[0], pair[1].artistId or 0))
    if not scored:
        return None

    best_score, best = scored[0]
    if (
        len(scored) > 1
        and best_score - scored[1][0] < 0.03
        and normalize_name(best.artistName or "")
        != normalize_name(scored[1][1].artistName or "")
    ):
        return None

    return best


def best_matching_album(
    results: Sequence[MusicItem],
    artist: str,
    title: str,
    track_count: int,
) -> MusicItem | None:
    """Choose a collection using artist, title, edition, and track count."""
    scored: list[tuple[float, MusicItem]] = []
    for item in results:
        if (
            item.wrapperType != "collection"
            or item.collectionId is None
            or item.collectionId <= 0
            or not item.collectionName
            or not item.artistName
            or not _same_edition(title, item.collectionName)
        ):
            continue

        artist_score = _similarity(artist, item.artistName)
        title_score = _similarity(title, item.collectionName)

        if artist_score < 0.90 or title_score < 0.88:
            continue

        score = 0.4 * artist_score + 0.6 * title_score

        if item.trackCount == track_count:
            score += 0.02

        scored.append((score, item))

    scored.sort(key=lambda pair: (-pair[0], pair[1].collectionId or 0))
    if not scored or scored[0][0] < 0.91:
        return None

    best_score, best = scored[0]
    if (
        len(scored) > 1
        and best_score - scored[1][0] < 0.03
        and (
            normalize_name(best.artistName or ""),
            normalize_name(best.collectionName or ""),
        )
        != (
            normalize_name(scored[1][1].artistName or ""),
            normalize_name(scored[1][1].collectionName or ""),
        )
    ):
        return None

    return best


def matching_itunes_tracks(
    results: Sequence[MusicItem],
    collection_id: int,
    discogs_tracks: Sequence[Track],
) -> list[MusicItem]:
    """Return an ordered collection only when its tracks fit the release."""
    tracks = [
        item
        for item in results
        if item.wrapperType == "track"
        and item.collectionId == collection_id
        and item.trackName
        and item.trackNumber is not None
        and item.trackNumber > 0
    ]
    tracks.sort(
        key=lambda item: (
            item.discNumber or 1,
            item.trackNumber or 0,
            item.trackId or 0,
        )
    )

    if not tracks or not discogs_tracks:
        return []

    selected = tracks[: len(discogs_tracks)]

    comparisons = [
        _similarity(discogs_track.title, itunes_track.trackName or "")
        for discogs_track, itunes_track in zip(discogs_tracks, selected, strict=False)
    ]

    if sum(comparisons) / len(comparisons) < 0.72:
        return []

    return selected


def matching_upc_tracks(
    results: Sequence[MusicItem],
    artist: str,
    title: str,
    discogs_tracks: Sequence[Track],
) -> list[MusicItem]:
    """Match a UPC result using artist and track evidence despite title suffixes."""
    if not discogs_tracks:
        return []

    matches: list[tuple[float, int, list[MusicItem]]] = []
    for album in results:
        if (
            album.wrapperType != "collection"
            or album.collectionId is None
            or album.collectionId <= 0
            or not album.artistName
            or not album.collectionName
        ):
            continue

        artist_score = _similarity(artist, album.artistName)
        title_score = _similarity(title, album.collectionName)
        if artist_score < 0.90 or title_score < 0.70:
            continue

        tracks = matching_itunes_tracks(results, album.collectionId, discogs_tracks)
        if len(tracks) / len(discogs_tracks) < 0.80:
            continue

        matches.append((artist_score + title_score, album.collectionId, tracks))

    if not matches:
        return []

    # Sort descendingly by score; break ties by collection ID.
    matches.sort(key=lambda match: (-match[0], match[1]))

    return matches[0][2]
