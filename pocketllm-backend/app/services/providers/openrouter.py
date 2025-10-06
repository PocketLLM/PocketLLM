"""OpenRouter provider implementation using OpenAI SDK compatibility."""

from __future__ import annotations

import logging
from typing import Any, Mapping

import httpx
from openai import AsyncOpenAI
from openai import OpenAIError

from app.core.config import Settings
from app.schemas.providers import ProviderModel

from .base import ProviderClient


class OpenRouterProviderClient(ProviderClient):
    """OpenRouter provider client using OpenAI SDK with OpenRouter's base URL."""

    provider = "openrouter"
    default_base_url = "https://openrouter.ai/api/v1"

    def __init__(
        self,
        settings: Settings,
        *,
        base_url: str | None = None,
        api_key: str | None = None,
        metadata: Mapping[str, Any] | None = None,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        super().__init__(
            settings,
            base_url=base_url,
            api_key=api_key,
            metadata=metadata,
            transport=transport,
        )
        self._logger = logging.getLogger(f"app.services.providers.{self.provider}")

    @property
    def base_url(self) -> str:
        if self._base_url_override:
            return self._base_url_override
        api_base = getattr(self._settings, "openrouter_api_base", None)
        return api_base or self.default_base_url

    async def list_models(self) -> list[ProviderModel]:
        """Fetch available models from OpenRouter using OpenAI SDK."""
        api_key = self._get_api_key()
        if self.requires_api_key and not api_key:
            self._logger.warning(
                "Skipping %s provider because credentials are not configured", self.provider
            )
            return []

        client = AsyncOpenAI(
            base_url=self.base_url,
            api_key=api_key,
            default_headers=self._build_openrouter_headers(),
        )

        try:
            models_response = await client.models.list()
            return self._parse_models(models_response)

        except OpenAIError as exc:
            self._logger.error("OpenRouter API request failed: %s", exc)
            return []
        except Exception:
            self._logger.exception("Unexpected error while fetching models from %s", self.provider)
            return []
        finally:
            await client.close()

    def _build_openrouter_headers(self) -> dict[str, str]:
        """Build OpenRouter-specific headers for ranking and attribution."""
        headers: dict[str, str] = {}
        metadata = self.metadata or {}

        app_url = (
            metadata.get("http_referer")
            or metadata.get("referer")
            or getattr(self._settings, "openrouter_app_url", None)
        )
        app_name = (
            metadata.get("x_title")
            or metadata.get("app_name")
            or getattr(self._settings, "openrouter_app_name", None)
        )

        if app_url:
            headers["HTTP-Referer"] = str(app_url)
        if app_name:
            headers["X-Title"] = str(app_name)

        extra_headers = metadata.get("headers")
        if isinstance(extra_headers, Mapping):
            headers.update({str(key): str(value) for key, value in extra_headers.items()})

        return headers

    def _parse_models(self, payload: Any) -> list[ProviderModel]:
        """Parse OpenRouter models response into ProviderModel objects."""
        models: list[ProviderModel] = []

        try:
            if hasattr(payload, "data"):
                model_list = payload.data
            elif isinstance(payload, Mapping) and "data" in payload:
                model_list = payload["data"]
            else:
                self._logger.warning("Unexpected OpenRouter models response format")
                return models

            for model_data in model_list:
                try:
                    if hasattr(model_data, "model_dump"):
                        model_mapping = model_data.model_dump()
                    elif isinstance(model_data, Mapping):
                        model_mapping = dict(model_data)
                    else:
                        self._logger.debug(
                            "Skipping OpenRouter model with unsupported type: %s", type(model_data)
                        )
                        continue

                    model_id = model_mapping.get("id", "")
                    if not model_id:
                        continue

                    name = model_mapping.get("name", model_id)

                    architecture = model_mapping.get("architecture", {}) or {}
                    input_modalities = architecture.get("input_modalities", []) or []
                    output_modalities = architecture.get("output_modalities", []) or []

                    top_provider = model_mapping.get("top_provider", {}) or {}
                    context_length = top_provider.get("context_length")
                    max_completion_tokens = top_provider.get("max_completion_tokens")

                    pricing = model_mapping.get("pricing", {}) or None

                    metadata: dict[str, Any] = {
                        "created": model_mapping.get("created"),
                        "description": model_mapping.get("description"),
                        "architecture": {
                            "input_modalities": input_modalities,
                            "output_modalities": output_modalities,
                            "tokenizer": architecture.get("tokenizer"),
                            "instruct_type": architecture.get("instruct_type"),
                        },
                        "top_provider": {
                            "is_moderated": top_provider.get("is_moderated"),
                        },
                        "capabilities": [],
                    }

                    if "text" in input_modalities:
                        metadata["capabilities"].append("text_input")
                    if "image" in input_modalities:
                        metadata["capabilities"].append("image_input")
                    if "text" in output_modalities:
                        metadata["capabilities"].append("text_output")

                    models.append(
                        ProviderModel(
                            provider=self.provider,
                            id=model_id,
                            name=name,
                            description=model_mapping.get("description"),
                            context_window=context_length,
                            max_output_tokens=max_completion_tokens,
                            pricing=pricing,
                            is_active=True,
                            metadata=metadata,
                        )
                    )

                except Exception as exc:
                    self._logger.warning(
                        "Failed to parse OpenRouter model %s: %s",
                        model_mapping.get("id", "unknown") if "model_mapping" in locals() else "unknown",
                        exc,
                    )
                    continue

        except Exception as exc:
            self._logger.error("Failed to parse OpenRouter models response: %s", exc)

        return models

    async def _fetch_payload(self, headers: dict[str, str]) -> Any:
        """Fallback method using direct HTTP requests if OpenAI SDK fails."""
        try:
            async with httpx.AsyncClient(
                base_url=self.base_url,
                headers=headers,
                timeout=self.timeout,
                transport=self._transport,
            ) as client:
                response = await client.get("/models")
                response.raise_for_status()
                return response.json()
        except Exception as exc:
            self._logger.error("OpenRouter HTTP fallback request failed: %s", exc)
            raise


__all__ = ["OpenRouterProviderClient"]
