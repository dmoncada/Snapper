# Snapper Metadata API

FastAPI service for Snapper's Discogs album searches and iTunes-first tracklist resolution.
The iOS app is not connected to this service yet.

## Local development

Copy `.env.example` to `.env` and set `DISCOGS_TOKEN`. The service also accepts the
same variable from the process environment, which takes precedence over `.env`.
Never commit `.env` or a production token. For deployment, supply the token through
the host's secret/configuration system.

```sh
cd backend/api
uv sync
uv run fastapi dev
```

The API is available at `http://127.0.0.1:8000`, with interactive docs at
`/docs`. Check `GET /health` before exercising the provider-backed endpoints.

## Deploy with FastAPI Cloud CLI

From `backend/api`, run `uv run fastapi deploy`. On the first run, the CLI guides
you through login and app creation, then saves the app link in `.fastapicloud`.
After the app exists, set the production token with
`uv run fastapi cloud env set --secret DISCOGS_TOKEN` and enter the value at the
hidden prompt. Run `uv run fastapi deploy` again to apply it. Subsequent
deployments use the same command. The local `.env` is ignored when packaging.

Use one Uvicorn worker for v1: cache and request pacing are process-local. A
multiworker deployment needs shared rate limiting and caching. Put HTTPS at a
trusted reverse proxy before exposing the service. The API does not authenticate
users or verify App Attest yet, so do not treat its endpoints as private.

## Endpoints

- `GET /health`
- `GET /v1/albums/search?q=...` — Discogs release search, at most 10 results
- `GET /v1/albums/by-barcode/{barcode}` — Discogs release barcode search, at most 5 results
- `POST /v1/tracklists/resolve` — body `{"discogsReleaseId": 123, "artist": "...", "title": "..."}`

Responses use the app's existing candidate and track field names. The tracklist
response contains `source`, `itunesUrl`, and `tracks`. Artwork and audio preview
URLs are returned to the app; their content is not proxied. iTunes uses the `us`
storefront, matching the current app. Any iTunes lookup failure falls back to the
Discogs release tracklist. A Discogs failure returns 502 or 503; provider errors
are not cached. Empty successful results are cached briefly.

Inputs are bounded, callers are limited to 60 requests/minute per observed IP,
and upstream requests are paced. The proxy must not expose docs or trust forwarded
client IP headers without its own access policy. Monitor provider 429 responses and
adjust pacing as their limits change. Cache duration and stored data must remain
consistent with provider terms.

```sh
uv run pytest
```

With the service running locally, `uv run python tests/live_smoke.py` sends the
app-shaped requests to the live API and checks the returned data and fallback.
