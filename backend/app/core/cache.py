"""Shared, best-effort caching for catalog API responses."""

from collections.abc import Awaitable, Callable
from hashlib import sha256

from pydantic import BaseModel, ValidationError
from redis_fastapi import CacheBackend

MIN = 60
HOUR = 60 * MIN
DAY = 24 * HOUR


def catalog_cache_key(namespace: str, request: BaseModel) -> str:
    """Include every provider request parameter without creating long Redis keys."""

    payload = request.model_dump_json(by_alias=True)
    digest = sha256(payload.encode()).hexdigest()

    return f"catalog:v1:{namespace}:{digest}"


async def cached_model[ModelT: BaseModel](
    cache: CacheBackend,
    key: str,
    model_type: type[ModelT],
    func: Callable[[], Awaitable[ModelT]],
    *,
    ttl: int,
    empty_ttl: int | None = None,
) -> ModelT:
    """Cache successful responses; let provider failures propagate normally."""

    cached = await cache.get(key)
    if cached is not None:
        try:
            return model_type.model_validate(cached)
        except ValidationError:
            pass

    response = await func()
    response_ttl = ttl

    if empty_ttl is not None and not getattr(response, "results", True):
        response_ttl = empty_ttl

    if response_ttl > 0:
        await cache.set(key, response.model_dump(mode="json"), ttl=response_ttl)

    return response


async def cached_provider_call[ModelT: BaseModel](
    cache: CacheBackend,
    *,
    namespace: str,
    request: BaseModel,
    response_model: type[ModelT],
    fetch: Callable[[], Awaitable[ModelT]],
    ttl: int,
    empty_ttl: int | None = None,
) -> ModelT:
    """Cache a provider response using its complete request model as the key."""

    return await cached_model(
        cache,
        catalog_cache_key(namespace, request),
        response_model,
        fetch,
        ttl=ttl,
        empty_ttl=empty_ttl,
    )
