# Prompt Engineering Notes

PocketLLM's backend delegates to upstream AI providers. When constructing prompts, ensure the following guidelines are respected:

- Include the chat history retrieved via `/v1/chats/{chatId}/messages` before sending to the provider.
- Prepend any configured system prompt from the selected `model_config.settings.system_prompt`.
- Track usage metrics (tokens, latency) in the `messages.metadata` column to support analytics dashboards.
- For image generation jobs, persist prompt parameters within `jobs.input_data` so retries have deterministic behaviour.

Prompt templates should live alongside the agents or orchestration layer that consumes this backend.
