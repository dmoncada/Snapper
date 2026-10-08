import re
import unicodedata

QUALIFIERS = {"anniversary", "deluxe", "expanded", "live", "remaster", "remastered"}


def normalize(value: str) -> str:
    folded = unicodedata.normalize("NFKD", value.casefold())
    ascii_text = "".join(char for char in folded if not unicodedata.combining(char))
    return " ".join(re.findall(r"[^\W_]+", ascii_text, flags=re.UNICODE))


def jaro_winkler(left: str, right: str) -> float:
    if left == right:
        return 1.0
    if not left or not right:
        return 0.0

    left_matches = [False] * len(left)
    right_matches = [False] * len(right)
    window = max(0, max(len(left), len(right)) // 2 - 1)
    matches = 0
    for index, char in enumerate(left):
        for other in range(max(0, index - window), min(index + window + 1, len(right))):
            if not right_matches[other] and char == right[other]:
                left_matches[index] = right_matches[other] = True
                matches += 1
                break
    if not matches:
        return 0.0

    matched_left = [char for char, matched in zip(left, left_matches) if matched]
    matched_right = [char for char, matched in zip(right, right_matches) if matched]
    transpositions = sum(a != b for a, b in zip(matched_left, matched_right)) // 2
    jaro = (
        matches / len(left)
        + matches / len(right)
        + (matches - transpositions) / matches
    ) / 3
    prefix = 0
    for a, b in zip(left[:4], right[:4]):
        if a != b:
            break
        prefix += 1
    return jaro + prefix * 0.1 * (1 - jaro)


def _compatible_edition(left: str, right: str) -> bool:
    def editions(text: str) -> list[str]:
        return sorted(word for word in normalize(text).split() if word in QUALIFIERS)

    return editions(left) == editions(right)


def best_collection(results: list[dict], artist: str, title: str) -> dict | None:
    scored: list[tuple[float, dict]] = []
    for result in results:
        other_artist = result.get("artistName")
        other_title = result.get("collectionName")
        collection_id = result.get("collectionId")
        if (
            not other_artist
            or not other_title
            or not isinstance(collection_id, int)
            or collection_id <= 0
        ):
            continue
        if not _compatible_edition(title, other_title):
            continue
        artist_score = jaro_winkler(normalize(artist), normalize(other_artist))
        title_score = jaro_winkler(normalize(title), normalize(other_title))
        if artist_score >= 0.92 and title_score >= 0.90:
            scored.append((artist_score * 0.4 + title_score * 0.6, result))

    scored.sort(key=lambda item: item[0], reverse=True)
    if not scored or scored[0][0] < 0.93:
        return None
    if len(scored) > 1 and scored[0][0] - scored[1][0] < 0.05:
        return None
    return scored[0][1]


def best_artist(results: list[dict], artist: str) -> dict | None:
    scored = [
        (jaro_winkler(normalize(artist), normalize(result["artistName"])), result)
        for result in results
        if result.get("artistName") and result.get("artistId") is not None
    ]
    scored.sort(key=lambda item: item[0], reverse=True)
    if not scored or scored[0][0] < 0.96:
        return None
    if len(scored) > 1 and scored[0][0] - scored[1][0] < 0.05:
        return None
    return scored[0][1]
