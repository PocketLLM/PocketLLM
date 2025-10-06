"""ImageRouter provider implementation for image generation models."""

from __future__ import annotations

import logging
from typing import Any, Mapping

import httpx

from app.core.config import Settings
from app.schemas.providers import ProviderModel

from .base import ProviderClient


class ImageRouterProviderClient(ProviderClient):
    """ImageRouter provider client for image generation models."""

    provider = "imagerouter"
    default_base_url = "https://api.imagerouter.io/v1/openai"

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
        return self.default_base_url

    async def list_models(self) -> list[ProviderModel]:
        """Fetch available image generation models from ImageRouter."""
        api_key = self._get_api_key()
        if self.requires_api_key and not api_key:
            self._logger.warning(
                "Skipping %s provider because credentials are not configured", self.provider
            )
            return []

        headers = self._build_headers(api_key)

        try:
            async with httpx.AsyncClient(
                base_url=self.base_url,
                headers=headers,
                timeout=self.timeout,
                transport=self._transport,
            ) as client:
                response = await client.get("/models")
                response.raise_for_status()
                return self._parse_models(response.json())

        except httpx.HTTPStatusError as exc:
            self._logger.error(
                "ImageRouter HTTP error %s: %s",
                exc.response.status_code,
                exc.response.text,
            )
            return []
        except httpx.HTTPError as exc:
            self._logger.error("ImageRouter HTTP request failed: %s", exc)
            return []
        except Exception:
            self._logger.exception("Unexpected error while fetching models from %s", self.provider)
            return []

    def _build_headers(self, api_key: str | None) -> dict[str, str]:
        """Build headers for ImageRouter API requests."""
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"

        metadata = self.metadata or {}
        extra_headers = metadata.get("headers")
        if isinstance(extra_headers, Mapping):
            headers.update({str(key): str(value) for key, value in extra_headers.items()})

        return headers

    def _parse_models(self, payload: Any) -> list[ProviderModel]:
        """Parse ImageRouter models response into ProviderModel objects."""
        models: list[ProviderModel] = []

        try:
            if isinstance(payload, Mapping) and "data" in payload:
                model_list = payload["data"]
            elif hasattr(payload, "data"):
                model_list = payload.data
            else:
                self._logger.warning(
                    "Unexpected ImageRouter models response format: %s", type(payload)
                )
                return models

            for model_data in model_list:
                try:
                    if hasattr(model_data, "model_dump"):
                        model_mapping = model_data.model_dump()
                    elif isinstance(model_data, Mapping):
                        model_mapping = dict(model_data)
                    else:
                        self._logger.debug(
                            "Skipping ImageRouter model with unsupported type: %s", type(model_data)
                        )
                        continue

                    model_id = model_mapping.get("id", "")
                    if not model_id:
                        continue

                    name = model_mapping.get("name", model_id.replace("_", " ").title())

                    metadata: dict[str, Any] = {
                        "created": model_mapping.get("created"),
                        "owned_by": model_mapping.get("owned_by", "ImageRouter"),
                        "capabilities": ["image_generation"],
                        "provider": model_mapping.get("provider"),
                    }

                    if "supported_formats" in model_mapping:
                        metadata["supported_formats"] = model_mapping["supported_formats"]
                    if "quality_levels" in model_mapping:
                        metadata["quality_levels"] = model_mapping["quality_levels"]
                    if "size_options" in model_mapping:
                        metadata["size_options"] = model_mapping["size_options"]

                    models.append(
                        ProviderModel(
                            provider=self.provider,
                            id=model_id,
                            name=name,
                            description=model_mapping.get(
                                "description", f"Image generation model: {name}"
                            ),
                            context_window=None,
                            max_output_tokens=None,
                            pricing=model_mapping.get("pricing"),
                            is_active=True,
                            metadata=metadata,
                        )
                    )

                except Exception as exc:
                    self._logger.warning(
                        "Failed to parse ImageRouter model %s: %s",
                        model_mapping.get("id", "unknown") if "model_mapping" in locals() else "unknown",
                        exc,
                    )
                    continue

        except Exception as exc:
            self._logger.error("Failed to parse ImageRouter models response: %s", exc)

        return models

    async def generate_image(self, prompt: str, model: str, **kwargs: Any) -> dict[str, Any]:
        """Generate an image using ImageRouter API."""
        api_key = self._get_api_key()
        if not api_key:
            raise ValueError("ImageRouter API key is not configured")

        headers = self._build_headers(api_key)

        payload: dict[str, Any] = {
            "prompt": prompt,
            "model": model,
        }

        if "quality" in kwargs:
            payload["quality"] = kwargs["quality"]
        if "size" in kwargs:
            payload["size"] = kwargs["size"]
        if "response_format" in kwargs:
            payload["response_format"] = kwargs["response_format"]
        if "num_images" in kwargs:
            payload["n"] = kwargs["num_images"]

        try:
            async with httpx.AsyncClient(
                base_url=self.base_url,
                headers=headers,
                timeout=self.timeout * 2,
                transport=self._transport,
            ) as client:
                response = await client.post("/images/generations", json=payload)
                response.raise_for_status()
                return response.json()

        except httpx.HTTPStatusError as exc:
            error_msg = (
                f"ImageRouter API error {exc.response.status_code}: {exc.response.text}"
            )
            self._logger.error(error_msg)
            raise RuntimeError(error_msg) from exc
        except Exception as exc:
            error_msg = f"Image generation failed: {exc}"
            self._logger.error(error_msg)
            raise RuntimeError(error_msg) from exc


__all__ = ["ImageRouterProviderClient"]
