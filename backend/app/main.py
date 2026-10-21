from contextlib import asynccontextmanager

import sentry_sdk
from fastapi import FastAPI

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
    sentry_sdk.init(dsn=str(settings.SENTRY_DSN), enable_tracing=True)


app = FastAPI(lifespan=lifespan)

app.frontend("/", directory="dist")

app.include_router(router, prefix=settings.API_V1_STR)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
