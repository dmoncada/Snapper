from typing import Any

import pycountry
from pydantic import BaseModel, ConfigDict


class Country(BaseModel):
    model_config = ConfigDict(frozen=True)

    alpha_2: str
    alpha_3: str
    numeric: str
    name: str
    official_name: str | None = None


def normalize_country(value: Any) -> Country | None:
    """Normalize a Discogs country value to ISO country metadata."""
    if not isinstance(value, str) or not value.strip():
        return None

    value = value.strip()

    # Prefer exact ISO alpha-2 code matching, then general lookup.
    country = pycountry.countries.get(alpha_2=value.upper())
    if country is None:
        try:
            country = pycountry.countries.lookup(value)
        except LookupError:
            return None

    return Country(
        alpha_2=country.alpha_2,
        alpha_3=country.alpha_3,
        numeric=country.numeric,
        name=country.name,
        official_name=getattr(country, "official_name", None),
    )
