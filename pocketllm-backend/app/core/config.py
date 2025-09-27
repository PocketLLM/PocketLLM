"""Application configuration module."""

from __future__ import annotations

from functools import lru_cache
from typing import List

from pydantic import AnyHttpUrl, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Centralised application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=(".env", ".env.local"), 
        env_file_encoding="utf-8",
        extra="ignore"  # Ignore extra environment variables
    )

    app_name: str = "PocketLLM API"
    environment: str = Field(default="development", alias="ENVIRONMENT")
    debug: bool = False
    version: str = "0.1.0"
    api_v1_prefix: str = "/v1"

    # Server configuration
    port: int = 8000
    node_env: str = "development"
    
    # CORS configuration
    backend_cors_origins: List[AnyHttpUrl] | List[str] = Field(
        default_factory=lambda: ["https://pocket-llm-api.vercel.app"],
    )
    cors_origin: str = "*"

    # URLs
    backend_base_url: str = "https://pocket-llm-api.vercel.app/"
    fallback_backend_url: str = "https://pocketllm.onrender.com"

    # Supabase configuration
    supabase_url: AnyHttpUrl = Field(default="https://example.supabase.co")  # type: ignore
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
    encryption_key: str = ""

    # Logging configuration
    log_level: str = Field(default="INFO", validation_alias="LOG_LEVEL")
    log_json: bool = Field(default=False, validation_alias="LOG_JSON", json_schema_extra={"example": False})

    # Storage configuration
    storage_bucket_models: str = "model-artifacts"
    storage_bucket_jobs: str = "job-results"
    user_asset_bucket_name: str = "user-assets"

    # Provider configuration
    openai_api_key: str | None = Field(default=None, alias="OPENAI_API_KEY")
    openai_api_base: str | None = Field(default=None, alias="OPENAI_API_BASE")
    groq_api_key: str | None = Field(default=None, alias="GROQ_API_KEY")
    groq_api_base: str | None = Field(default=None, alias="GROQ_API_BASE")
    openrouter_api_key: str | None = Field(default=None, alias="OPENROUTER_API_KEY")
    openrouter_api_base: str | None = Field(default=None, alias="OPENROUTER_API_BASE")
    openrouter_app_url: str | None = Field(default=None, alias="OPENROUTER_APP_URL")
    openrouter_app_name: str | None = Field(default=None, alias="OPENROUTER_APP_NAME")
    provider_catalogue_cache_ttl: int = Field(
        default=60, alias="PROVIDER_CATALOGUE_CACHE_TTL"
    )


@lru_cache
def get_settings() -> Settings:
    """Return a cached instance of :class:`Settings`."""

    return Settings()  # type: ignore[arg-type]


__all__ = ["Settings", "get_settings"]