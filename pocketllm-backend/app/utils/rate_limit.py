"""Simple in-memory rate limiter."""

from __future__ import annotations

import asyncio
import time
from collections import deque
from typing import Deque, Dict

from fastapi import HTTPException, status


class RateLimiter:
    """Token-bucket style limiter for lightweight scenarios."""

    def __init__(self, max_requests: int, window_seconds: float) -> None:
        self._max_requests = max_requests
        self._window = window_seconds
        self._lock = asyncio.Lock()
        self._requests: Dict[str, Deque[float]] = {}

    async def check(self, key: str) -> None:
        now = time.monotonic()
        async with self._lock:
            bucket = self._requests.setdefault(key, deque())
            while bucket and now - bucket[0] > self._window:
                bucket.popleft()
            if len(bucket) >= self._max_requests:
                retry_after = max(0.0, self._window - (now - bucket[0]))
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Rate limit exceeded",
                    headers={"Retry-After": f"{retry_after:.0f}"},
                )
            bucket.append(now)


__all__ = ["RateLimiter"]
