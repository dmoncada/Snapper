from typing import Literal

from pydantic import HttpUrl
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_ignore_empty=True,
        extra="ignore",
    )

    API_V1_STR: str = "/api/v1"
    FASTAPI_ENV: Literal["development"] | None = None

    DISCOGS_TOKEN: str = ""
    SENTRY_DSN: HttpUrl | None = None

    REDIS_HOST: str = ""
    REDIS_PORT: int = 6380
    REDIS_DB: int = 0
    REDIS_USERNAME: str = ""
    REDIS_PASSWORD: str = ""


settings = Settings()
