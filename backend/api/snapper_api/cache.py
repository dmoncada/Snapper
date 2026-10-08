import asyncio
import time
from collections import OrderedDict, deque
from collections.abc import Awaitable, Callable
from typing import TypeVar

T = TypeVar("T")


class TtlCache:
    def __init__(self, max_entries: int = 512):
        self._items: OrderedDict[str, tuple[float, object]] = OrderedDict()
        self._max_entries = max_entries
        self._lock = asyncio.Lock()

    async def get_or_load(
        self, key: str, ttl_seconds: float, loader: Callable[[], Awaitable[T]]
    ) -> T:
        async with self._lock:
            entry = self._items.get(key)
            if entry and entry[0] > time.monotonic():
                self._items.move_to_end(key)
                return entry[1]  # type: ignore[return-value]

        value = await loader()
        async with self._lock:
            self._items[key] = (time.monotonic() + ttl_seconds, value)
            self._items.move_to_end(key)
            while len(self._items) > self._max_entries:
                self._items.popitem(last=False)
        return value


class SlidingWindowLimiter:
    def __init__(self, limit: int, period_seconds: float):
        self._limit = limit
        self._period = period_seconds
        self._requests: dict[str, deque[float]] = {}
        self._lock = asyncio.Lock()

    async def allow(self, key: str) -> bool:
        now = time.monotonic()
        async with self._lock:
            times = self._requests.setdefault(key, deque())
            while times and times[0] <= now - self._period:
                times.popleft()
            if len(times) >= self._limit:
                return False
            times.append(now)
            return True


class UpstreamPacer:
    def __init__(self, spacing_seconds: float):
        self._spacing = spacing_seconds
        self._next = 0.0
        self._lock = asyncio.Lock()

    async def wait(self) -> None:
        async with self._lock:
            now = time.monotonic()
            delay = max(0.0, self._next - now)
            if delay:
                await asyncio.sleep(delay)
            self._next = time.monotonic() + self._spacing
