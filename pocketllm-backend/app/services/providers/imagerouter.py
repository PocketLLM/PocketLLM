"""ImageRouter provider implementation for image generation models."""

from __future__ import annotations

import logging
from collections import deque
from typing import Any, Mapping

import httpx

from app.core.config import Settings
from app.schemas.providers import ProviderModel

from .base import ProviderClient


class ImageRouterProviderClient(ProviderClient):
    """ImageRouter provider client for image generation models."""

    provider = "imagerouter"
    default_base_url = "https://api.imagerouter.io"
    models_endpoint = "/v1/models"
    requires_api_key = False

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
        api_base = getattr(self._settings, "imagerouter_api_base", None)
        if isinstance(api_base, str) and api_base.strip():
            return api_base.strip()
        return self.default_base_url

    def _get_api_key(self) -> str | None:
        if self._api_key_override:
            return self._api_key_override
        api_key = getattr(self._settings, "imagerouter_api_key", None)
        if isinstance(api_key, str):
            api_key = api_key.strip()
            if api_key:
                return api_key
        return None

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
                response = await client.get(self.models_endpoint)
                response.raise_for_status()
                payload = response.json()
                models = self._parse_models(payload)
                if models:
                    self._logger.debug(
                        "Fetched %d models from %s", len(models), self.provider
                    )
                return models

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
            self._logger.exception(
                "Unexpected error while fetching models from %s", self.provider
            )
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
            model_list = self._extract_model_list(payload)
            if model_list is None:
                self._logger.warning(
                    "Unexpected ImageRouter models response format: %s",
                    self._summarise_payload(payload),
                )
                return models

            raw_entries = len(model_list)
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

                    model_id = str(model_mapping.get("id", "")).strip()
                    if not model_id:
                        continue

                    name = model_mapping.get("name") or model_id.replace("_", " ").title()

                    metadata: dict[str, Any] = {}
                    capabilities = model_mapping.get("capabilities")
                    if isinstance(capabilities, list) and capabilities:
                        metadata["capabilities"] = capabilities
                    else:
                        metadata["capabilities"] = ["image_generation"]

                    for key in ("supported_formats", "quality_levels", "size_options"):
                        value = model_mapping.get(key)
                        if value:
                            metadata[key] = value

                    for key in ("created", "owned_by", "provider"):
                        value = model_mapping.get(key)
                        if value not in (None, ""):
                            metadata[key] = value

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
                            metadata=metadata or None,
                        )
                    )

                except Exception as exc:
                    self._logger.warning(
                        "Failed to parse ImageRouter model entry: %s",
                        exc,
                    )
                    continue

        except Exception as exc:
            self._logger.error("Failed to parse ImageRouter models response: %s", exc)
        else:
            if not models:
                self._logger.warning(
                    "ImageRouter response contained %d entries but none were usable; payload summary=%s",
                    raw_entries,
                    self._summarise_payload(payload),
                )

        return models

    def _extract_model_list(self, payload: Any) -> list[Any] | None:
        """Normalise the ImageRouter response payload into a list of model entries."""

        for extractor in (
            self._extract_from_mapping,
            self._extract_from_attribute,
        ):
            models = extractor(payload)
            if models is not None:
                return models
        if isinstance(payload, list) and any(self._is_model_entry(item) for item in payload):
            return payload

        return None

    def _extract_from_mapping(self, payload: Any) -> list[Any] | None:
        if not isinstance(payload, Mapping):
            return None

        search_queue: deque[Any] = deque([payload])
        seen: set[int] = set()

        while search_queue:
            current = search_queue.popleft()
            current_id = id(current)
            if current_id in seen:
                continue
            seen.add(current_id)

            if isinstance(current, list):
                if any(self._is_model_entry(item) for item in current):
                    return current
                continue

            if not isinstance(current, Mapping):
                continue

            for key in ("models", "data", "items", "results", "entries", "list"):
                if key not in current:
                    continue
                candidate = current[key]
                if isinstance(candidate, list) and any(
                    self._is_model_entry(item) for item in candidate
                ):
                    return candidate
                if isinstance(candidate, (Mapping, list)):
                    search_queue.append(candidate)

            for value in current.values():
                if isinstance(value, list) and any(
                    self._is_model_entry(item) for item in value
                ):
                    return value
                if isinstance(value, (Mapping, list)):
                    search_queue.append(value)

        return None

    def _extract_from_attribute(self, payload: Any) -> list[Any] | None:
        for attr in ("data", "models", "items", "results"):
            if hasattr(payload, attr):
                value = getattr(payload, attr)
                if isinstance(value, list) and any(
                    self._is_model_entry(item) for item in value
                ):
                    return value
                if isinstance(value, Mapping):
                    nested = self._extract_from_mapping(value)
                    if nested is not None:
                        return nested
        return None

    def _is_model_entry(self, value: Any) -> bool:
        return isinstance(value, Mapping) or hasattr(value, "model_dump")

    def _summarise_payload(self, payload: Any) -> str:
        try:
            if isinstance(payload, Mapping):
                keys = list(payload.keys())
                sample_types = {
                    key: type(payload[key]).__name__ for key in keys[:5]
                }
                nested_keys: dict[str, list[str]] = {}
                for key in keys[:3]:
                    nested_value = payload[key]
                    if isinstance(nested_value, Mapping):
                        nested_keys[key] = list(nested_value.keys())[:5]
                parts = [f"keys={keys[:5]}", f"types={sample_types}"]
                if nested_keys:
                    parts.append(f"nested_keys={nested_keys}")
                summary = ", ".join(parts)
                return f"mapping({summary})"
            if isinstance(payload, list):
                item_types = [type(item).__name__ for item in payload[:5]]
                return f"list(len={len(payload)}, item_types={item_types})"
            return repr(payload)
        except Exception as exc:  # pragma: no cover - defensive logging
            return f"{type(payload).__name__} (summary unavailable: {exc})"

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
                response = await client.post("/v1/openai/images/generations", json=payload)
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
