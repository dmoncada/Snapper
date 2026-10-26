import logging
from contextlib import asynccontextmanager

import sentry_sdk
from fastapi import FastAPI
from redis_fastapi import FastAPIRedis
from sentry_sdk.integrations.logging import LoggingIntegration

from app.api.main import router
from app.core.config import settings
from app.providers.discogs.client import DiscogsClient, create_discogs_http_client
from app.providers.itunes.client import ItunesClient, create_itunes_http_client


@asynccontextmanager
async def lifespan(app: FastAPI):
    token = settings.DISCOGS_TOKEN
    async with create_discogs_http_client(token) as discogs_http:
        async with create_itunes_http_client() as itunes_http:
            app.state.discogs = DiscogsClient(discogs_http)
            app.state.itunes = ItunesClient(itunes_http)
            yield


if settings.SENTRY_DSN and settings.FASTAPI_ENV != "development":
    sentry_sdk.init(
        dsn=str(settings.SENTRY_DSN),
        enable_tracing=True,
        integrations=[
            LoggingIntegration(
                level=logging.WARNING,
                event_level=logging.WARNING,
                sentry_logs_level=logging.WARNING,
                capture_sentry_logs=True,
            )
        ],
    )

app = FastAPI(lifespan=lifespan)

app.frontend("/", directory="dist")

app.include_router(router, prefix=settings.API_V1_STR)

FastAPIRedis(app).lifespan().caching()


@app.get("/health")
@app.get(f"{settings.API_V1_STR}/health", include_in_schema=False)
async def health() -> dict[str, str]:
    return {"status": "ok"}
