from typing import Any

import pycountry
from pydantic import BaseModel, ConfigDict


class Country(BaseModel):
    model_config = ConfigDict(frozen=True)

    alpha2: str
    alpha3: str
    numeric: str
    name: str
    official_name: str | None = None


_COMMON_ALIASES = {
    "UK": "GB",
    "U.K.": "GB",
    "USA": "US",
    "U.S.": "US",
    "U.S.A.": "US",
}


def normalize_country(value: Any) -> Country | None:
    """Normalize a Discogs country value to ISO country metadata."""
    if not isinstance(value, str) or not value.strip():
        return None

    value = value.strip()
    value = _COMMON_ALIASES.get(value.upper(), value)

    # Prefer exact ISO alpha-2 code matching, then general lookup.
    country = pycountry.countries.get(alpha_2=value.upper())
    if country is None:
        try:
            country = pycountry.countries.lookup(value)
        except LookupError:
            return None

    return Country(
        alpha2=country.alpha_2,
        alpha3=country.alpha_3,
        numeric=country.numeric,
        name=country.name,
        official_name=getattr(country, "official_name", None),
    )
