"""Application configuration module."""

from __future__ import annotations

from functools import lru_cache
from typing import List

from pydantic import AnyHttpUrl, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Centralised application settings loaded from environment variables."""

    model_config = SettingsConfigDict(env_file=(".env", ".env.local"), env_file_encoding="utf-8")

    app_name: str = "PocketLLM API"
    environment: str = Field(default="development", alias="ENVIRONMENT")
    debug: bool = False
    version: str = "0.1.0"
    api_v1_prefix: str = "/v1"

    # CORS configuration
    backend_cors_origins: List[AnyHttpUrl] | List[str] = Field(
        default_factory=lambda: ["http://localhost", "http://localhost:3000"],
    )

    # Supabase configuration
    supabase_url: AnyHttpUrl = Field(default="https://example.supabase.co")
    supabase_service_role_key: str = Field(default="service-role-placeholder")
    supabase_anon_key: str = Field(default="anon-key-placeholder")
    supabase_jwt_secret: str | None = None
    supabase_jwt_audience: str = "authenticated"
    supabase_schema: str = "public"

    # Database connection (direct Postgres access through Supabase)
    database_url: str | None = Field(default=None, alias="SUPABASE_DB_URL")
    database_pool_min_size: int = 2
    database_pool_max_size: int = 10
    database_statement_timeout: int = 30_000

    # Redis / job queue configuration
    redis_url: str | None = None
    job_results_ttl_seconds: int = 60 * 60  # 1 hour
    job_default_timeout_seconds: int = 60 * 5

    # Security / authentication
    access_token_expire_minutes: int = 60 * 24
    refresh_token_expire_minutes: int = 60 * 24 * 14
    token_algorithm: str = "HS256"

    # Logging configuration
    log_level: str = Field(default="INFO", validation_alias="LOG_LEVEL")
    log_json: bool = Field(default=True, validation_alias="LOG_JSON", json_schema_extra={"example": True})

    # Storage configuration
    storage_bucket_models: str = "model-artifacts"
    storage_bucket_jobs: str = "job-results"


@lru_cache
def get_settings() -> Settings:
    """Return a cached instance of :class:`Settings`."""

    return Settings()  # type: ignore[arg-type]


__all__ = ["Settings", "get_settings"]
