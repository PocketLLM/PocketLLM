
# Groq API Guide (Extracted from API Reference)

> Source: Groq Cloud Docs â€” API Reference (`https://api.groq.com/openai/v1` endpoints)

This guide captures the endpoints and key request/response fields shown in the Groq API Reference page, organized for quick implementation.

---

## 1) Base URL and Auth

- **Base URL prefix**: `https://api.groq.com/openai/v1`
- **Authentication**: Bearer token
  - Header: `Authorization: Bearer $GROQ_API_KEY`
  - Typical extra header: `Content-Type: application/json` (or `multipart/form-data` for file/audio uploads)

---

## 2) Chat Completions

**Endpoint**: `POST /chat/completions`

Creates a model response for a chat conversation.

### Request Body (selected fields)
- `model` (string, **required**) â€” model id
- `messages` (array, **required**) â€” list of messages (`role`, `content`)
- `documents` (array) â€” text snippets for context
- `response_format` (object) â€” supports `{ "type": "json_object" }` or JSON schema structured output
- `tool_choice` (string|object) â€” `none` | `auto` | `required` or force a specific tool
- `tools` (array) â€” function tools (up to 128) with JSON schemas
- `stream` (boolean) â€” SSE streaming
- `stream_options` (object) â€” options for streaming
- `max_completion_tokens` (int) â€” cap on generated tokens
- `temperature` (number) â€” 0..2
- `top_p` (number) â€” 0..1
- `stop` (string|string[]) â€” up to 4 stop sequences
- `seed` (int) â€” best-effort determinism
- `service_tier` (string) â€” `auto` | `on_demand` | `flex` | `performance` (default `on_demand`)
- Reasoning-related (model-dependent):
  - `reasoning_effort` (string) â€” allowed values depend on model
  - `reasoning_format` (string) â€” `hidden` | `raw` | `parsed`
  - `include_reasoning` (boolean) â€” mutually exclusive with `reasoning_format`
- Deprecated: `functions`, `function_call`, `max_tokens`, `include_domains`, `exclude_domains` (use `search_settings` instead)
- Not currently supported by models (present in schema): `frequency_penalty`, `presence_penalty`, `logit_bias`, `logprobs`, `top_logprobs`, `metadata`, `store`

### Response (selected fields)
- `id`, `object: "chat.completion"`, `created`, `model`, `system_fingerprint`
- `choices[]` with `message { role, content }`, `finish_reason`
- `usage { prompt_tokens, completion_tokens, total_tokens, ... }`
- `usage_breakdown` for compound requests

### Example (curl)
```bash
curl https://api.groq.com/openai/v1/chat/completions -s   -H "Content-Type: application/json"   -H "Authorization: Bearer $GROQ_API_KEY"   -d '{
    "model": "llama-3.3-70b-versatile",
    "messages": [{"role":"user","content":"Explain the importance of fast language models"}]
  }'
```

---

## 3) Responses API (beta)

**Endpoint**: `POST /responses`

Generates a response given plain `input` (non-chat).

### Request Body (selected fields)
- `model` (string, **required**)
- `input` (string|array, **required**)
- `instructions` (string) â€” system/developer guidance
- `max_output_tokens` (int)
- `temperature` (number 0..2)
- `parallel_tool_calls` (boolean, default true)
- `reasoning` (object) â€” config for reasoning-capable models
- `service_tier` (string, default `auto`) â€” `auto` | `default` | `flex`
- `store` (boolean, default false)
- `stream` (boolean, default false)
- `text` (object) â€” response format selection

---

## 4) Audio

### 4.1 Transcription

**Endpoint**: `POST /audio/transcriptions`  
**Content-Type**: `multipart/form-data`

- Typical form fields: `file` (binary), `model` (e.g., `whisper-large-v3`)

**Example**
```bash
curl https://api.groq.com/openai/v1/audio/transcriptions   -H "Authorization: Bearer $GROQ_API_KEY"   -H "Content-Type: multipart/form-data"   -F file="@./sample_audio.m4a"   -F model="whisper-large-v3"
```

**Response**
```json
{
  "text": "Your transcribed text appears here...",
  "x_groq": {"id": "req_unique_id"}
}
```

### 4.2 Translation

**Endpoint**: `POST /audio/translations`  
**Content-Type**: `multipart/form-data`

- Typical form fields: `file` (binary), `model` (e.g., `whisper-large-v3`)

**Example**
```bash
curl https://api.groq.com/openai/v1/audio/translations   -H "Authorization: Bearer $GROQ_API_KEY"   -H "Content-Type: multipart/form-data"   -F file="@./sample_audio.m4a"   -F model="whisper-large-v3"
```

**Response**
```json
{
  "text": "Your translated text appears here...",
  "x_groq": {"id": "req_unique_id"}
}
```

### 4.3 Text-to-Speech

**Endpoint**: `POST /audio/speech`

- Selected fields: `model` (e.g., `playai-tts`), `input` (text), `voice`, `response_format` (e.g., `wav`)

**Example**
```bash
curl https://api.groq.com/openai/v1/audio/speech   -H "Authorization: Bearer $GROQ_API_KEY"   -H "Content-Type: application/json"   -d '{
    "model": "playai-tts",
    "input": "I love building and shipping new features for our users!",
    "voice": "Fritz-PlayAI",
    "response_format": "wav"
  }'
```

**Returns**: audio file content (e.g., WAV)

---

## 5) Models

### 5.1 List Models

**Endpoint**: `GET /models`

**Example response (abridged)**
```json
{
  "object": "list",
  "data": [
    {"id":"gemma2-9b-it","object":"model","owned_by":"Google","active":true,"context_window":8192},
    {"id":"llama3-8b-8192","object":"model","owned_by":"Meta","active":true,"context_window":8192},
    {"id":"llama-3.1-8b-instant","object":"model","owned_by":"Meta","active":true,"context_window":131072},
    {"id":"whisper-large-v3","object":"model","owned_by":"OpenAI","active":true,"context_window":448}
  ]
}
```

### 5.2 Retrieve Model

**Endpoint**: `GET /models/{model}`

**Returns**: `id`, `object: "model"`, `created`, `owned_by`, `active`, `context_window`, `max_completion_tokens` (when applicable)

---

## 6) Batches

### 6.1 Create Batch

**Endpoint**: `POST /batches`

Creates and executes a batch from a previously uploaded **JSONL** file.

**Request body (selected)**
- `endpoint` (string, **required**) â€” currently supports `/v1/chat/completions`
- `input_file_id` (string, **required**)
- `completion_window` (string, **required**) â€” duration `24h` to `7d`

### 6.2 Retrieve Batch

**Endpoint**: `GET /batches/{batch_id}`

### 6.3 List Batches

**Endpoint**: `GET /batches`

### 6.4 Cancel Batch

**Endpoint**: `POST /batches/{batch_id}/cancel`

**Batch object fields (selected)**  
`id`, `object:"batch"`, `endpoint`, `status` (`validating|failed|in_progress|finalizing|completed|expired|cancelling|cancelled`), `input_file_id`, `output_file_id`, `error_file_id`, timestamps: `in_progress_at`, `finalizing_at`, `failed_at`, `expires_at`, `expired_at`, `completed_at`, `cancelled_at`, counts: `request_counts { total, completed, failed }`, `metadata`

---

## 7) Files

### 7.1 Upload File

**Endpoint**: `POST /files`  
Use for batch inputs. **Only `.jsonl` up to 100 MB** for Batch API.

**multipart fields**
- `file` (binary, **required**)
- `purpose` (string, **required**) â€” `batch`

### 7.2 List Files

**Endpoint**: `GET /files`

### 7.3 Retrieve File

**Endpoint**: `GET /files/{file_id}`

### 7.4 Download File

**Endpoint**: `GET /files/{file_id}/content`

### 7.5 Delete File

**Endpoint**: `DELETE /files/{file_id}`

**File object fields (selected)**  
`id`, `object:"file"`, `bytes`, `created_at`, `filename`, `purpose` (`batch|batch_output`)

---

## 8) Fine Tuning (Closed Beta)

> Endpoints exist but are gated; contact Groq for access.

- **List**: `GET /v1/fine_tunings`
- **Create**: `POST /v1/fine_tunings`
  - Body: `input_file_id`, `name`, `type` (e.g., `"lora"`), `base_model`
- **Get**: `GET /v1/fine_tunings/{id}`
- **Delete**: `DELETE /v1/fine_tunings/{id}`

**Objects** expose: `id`, `name`, `base_model`, `type`, `input_file_id`, `created_at`, `fine_tuned_model`

---

## 9) Practical Notes

- Streaming uses **Server-Sent Events** with `data: [DONE]` terminator.
- Some request fields are present for forward-compatibility but not supported by current models (penalties, logprobs, etc.).
- For JSONL batch format, follow the documented â€œLearn moreâ€ spec referenced in the batch section.
- Reasoning controls are model-specific. Honor the allowed values indicated per model family.

---

## 10) Minimal Client Stubs

### Fetch (Node/Browser)
```js
async function chat(userMsg) {
  const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${process.env.GROQ_API_KEY}`
    },
    body: JSON.stringify({
      model: "llama-3.3-70b-versatile",
      messages: [{ role: "user", content: userMsg }]
    })
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}
```

### Python (requests)
```python
import os, requests, json

url = "https://api.groq.com/openai/v1/chat/completions"
headers = {
    "Authorization": f"Bearer {os.environ['GROQ_API_KEY']}",
    "Content-Type": "application/json"
}
payload = {
    "model": "llama-3.3-70b-versatile",
    "messages": [{"role":"user","content":"hello"}]
}
r = requests.post(url, headers=headers, data=json.dumps(payload), timeout=60)
r.raise_for_status()
print(r.json())
```

---

This file mirrors the visible fields and examples from the referenced API Reference and is suitable as a drop-in quickstart for implementation.