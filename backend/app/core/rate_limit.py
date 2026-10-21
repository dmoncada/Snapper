from __future__ import annotations

import asyncio
import time
from collections import deque

import httpx2


class SlidingWindowRateLimiter:
    """Limit request starts to max_requests in any rolling period."""

    def __init__(
        self,
        max_requests: int = 60,
        period: float = 60.0,
    ) -> None:
        if max_requests < 1:
            raise ValueError("max_requests must be >= 1")
        if period <= 0:
            raise ValueError("period must be > 0")

        self.max_requests = max_requests
        self.period = period
        self._timestamps: deque[float] = deque()
        self._lock = asyncio.Lock()

    async def acquire(self) -> None:
        while True:
            async with self._lock:
                now = time.monotonic()
                cutoff = now - self.period

                while self._timestamps and self._timestamps[0] <= cutoff:
                    self._timestamps.popleft()

                if len(self._timestamps) < self.max_requests:
                    self._timestamps.append(now)
                    return

                delay = self._timestamps[0] + self.period - now

            await asyncio.sleep(max(delay, 0.001))


class RateLimitedAsyncTransport(httpx2.AsyncBaseTransport):
    """Transport decorator that applies a shared sliding-window limit."""

    def __init__(
        self,
        transport: httpx2.AsyncBaseTransport,
        limiter: SlidingWindowRateLimiter,
    ) -> None:
        self._transport = transport
        self._limiter = limiter

    async def handle_async_request(
        self,
        request: httpx2.Request,
    ) -> httpx2.Response:
        await self._limiter.acquire()
        return await self._transport.handle_async_request(request)

    async def aclose(self) -> None:
        await self._transport.aclose()
