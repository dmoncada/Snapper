from contextlib import asynccontextmanager
from typing import Annotated

import httpx
from fastapi import Depends, FastAPI, HTTPException, Query, Request
from fastapi.responses import JSONResponse

from .cache import SlidingWindowLimiter, TtlCache
from .config import discogs_token
from .discogs import DiscogsClient
from .itunes import ItunesClient
from .models import AlbumCandidate, TracklistRequest, TracklistResponse
from .service import MetadataService
from .upstream import UpstreamError


def get_service(request: Request) -> MetadataService:
    return request.app.state.service


MetadataServiceDep = Annotated[MetadataService, Depends(get_service)]


def create_app(service: MetadataService | None = None) -> FastAPI:
    @asynccontextmanager
    async def lifespan(app: FastAPI):
        if service is None:
            timeout = httpx.Timeout(8.0, connect=3.0)
            async with httpx.AsyncClient(
                timeout=timeout, follow_redirects=False
            ) as client:
                app.state.service = MetadataService(
                    DiscogsClient(client, discogs_token()),
                    ItunesClient(client),
                )
                yield
        else:
            app.state.service = service
            yield

    app = FastAPI(title="Snapper Metadata API", version="1.0.0", lifespan=lifespan)
    cache = TtlCache()
    limiter = SlidingWindowLimiter(limit=60, period_seconds=60)

    @app.middleware("http")
    async def limit_requests(request: Request, call_next):
        if request.url.path in ("/health", "/openapi.json", "/docs", "/redoc"):
            return await call_next(request)
        # Deliberately ignore X-Forwarded-For until a trusted reverse proxy is configured.
        identity = request.client.host if request.client else "unknown"
        if not await limiter.allow(identity):
            return JSONResponse(
                {"detail": "Rate limit exceeded"},
                status_code=429,
                headers={"Retry-After": "60"},
            )
        return await call_next(request)

    @app.exception_handler(UpstreamError)
    async def upstream_error_handler(_request: Request, error: UpstreamError):
        if error.provider == "discogs" and not discogs_token() and service is None:
            return JSONResponse(
                {"detail": "Discogs is not configured"}, status_code=503
            )
        status = 503 if error.status_code == 429 else 502
        return JSONResponse(
            {"detail": f"{error.provider} is temporarily unavailable"},
            status_code=status,
        )

    @app.get("/health")
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/v1/albums/search")
    async def search_albums(
        q: Annotated[str, Query(min_length=1, max_length=120)],
        service: MetadataServiceDep,
    ) -> list[AlbumCandidate]:
        term = q.strip()
        if not term:
            raise HTTPException(status_code=422, detail="Search term is empty")
        return await cache.get_or_load(
            f"search:{term.casefold()}",
            300,
            lambda: service.discogs.search(query=term, limit=10),
        )

    @app.get("/v1/albums/by-barcode/{barcode}")
    async def albums_by_barcode(
        barcode: str, service: MetadataServiceDep
    ) -> list[AlbumCandidate]:
        code = barcode.strip()
        if not code.isdigit() or not 1 <= len(code) <= 32:
            raise HTTPException(
                status_code=422, detail="Barcode must contain 1–32 digits"
            )
        return await cache.get_or_load(
            f"barcode:{code}",
            300,
            lambda: service.discogs.search(barcode=code, limit=5),
        )

    @app.post("/v1/tracklists/resolve")
    async def resolve_tracklist(
        body: TracklistRequest, service: MetadataServiceDep
    ) -> TracklistResponse:
        if not body.artist.strip() or not body.title.strip():
            raise HTTPException(status_code=422, detail="Artist and title are required")
        cache_key = f"tracks:{body.discogsReleaseId}:{body.artist.strip().casefold()}:{body.title.strip().casefold()}"
        return await cache.get_or_load(
            cache_key,
            600,
            lambda: service.resolve_tracks(body),
        )

    return app


app = create_app()
