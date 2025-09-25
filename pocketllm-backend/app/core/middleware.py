"""Custom FastAPI middleware components."""

from __future__ import annotations

import time
import uuid

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint


class RequestContextMiddleware(BaseHTTPMiddleware):
    """Attach a request identifier to every incoming request."""

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        request.state.request_id = uuid.uuid4().hex
        response = await call_next(request)
        response.headers["X-Request-ID"] = request.state.request_id
        return response


class LoggingMiddleware(BaseHTTPMiddleware):
    """Structured logging for incoming requests."""

    def __init__(self, app, logger_name: str = "pocketllm.api") -> None:
        super().__init__(app)
        import logging

        self._logger = logging.getLogger(logger_name)

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        start_time = time.perf_counter()
        response = await call_next(request)
        process_time = (time.perf_counter() - start_time) * 1000

        self._logger.info(
            "HTTP request",
            extra={
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": round(process_time, 2),
                "request_id": getattr(request.state, "request_id", None),
                "client_ip": request.client.host if request.client else None,
            },
        )
        response.headers["X-Process-Time"] = str(round(process_time, 2))
        return response


__all__ = ["LoggingMiddleware", "RequestContextMiddleware"]
