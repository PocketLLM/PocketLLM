# Groq API Integration Guide

This document condenses Groq Cloud's official documentation into a practical handbook for PocketLLM. **Always** interact with
Groq through the official [`groq`](https://pypi.org/project/groq/) SDK. The backend now wraps that SDK inside
`GroqProviderClient` for catalogue aggregation and exposes high-level helpers via `GroqSDKService` for chat, responses, and
speech workflows.

## 1. Getting Started

1. Create an API key in the [Groq Cloud dashboard](https://console.groq.com/).
2. Export the key for local development so the SDK can read it automatically:
   ```bash
   export GROQ_API_KEY="<your-api-key-here>"
   ```
3. Install the Python SDK:
   ```bash
   pip install groq
   ```
4. Instantiate the client. The synchronous and asynchronous variants automatically pick up `GROQ_API_KEY`:
   ```python
   from groq import Groq, AsyncGroq

   sync_client = Groq()
   async_client = AsyncGroq()
   ```

### Third-party SDKs

Groq is compatible with popular orchestration layers if you prefer higher-level abstractions:

- **Vercel AI SDK** / `@ai-sdk/groq` provider
- **LiteLLM**
- **LangChain**

Example (Vercel AI SDK):
```javascript
import { groq } from '@ai-sdk/groq';
import { generateText } from 'ai';

const { text } = await generateText({
  model: groq('llama-3.3-70b-versatile'),
  prompt: 'Write a vegetarian lasagna recipe for 4 people.',
});
```

### OpenAI compatibility mode

Groq’s API is mostly OpenAI compatible. When you cannot depend on the `groq` SDK, configure the official OpenAI client with the
Groq base URL:
```python
from openai import OpenAI

client = OpenAI(
    api_key=os.environ["GROQ_API_KEY"],
    base_url="https://api.groq.com/openai/v1",
)
```
Unsupported OpenAI parameters include `logprobs`, `logit_bias`, `top_logprobs`, `messages[].name`, and `N != 1`. Supplying a
temperature of `0` coerces it to `1e-8`.

## 2. Endpoint Overview & Unsupported Features

Groq mirrors OpenAI’s REST layout at `https://api.groq.com/openai/v1`:

| Capability            | HTTP Verb | Endpoint                         |
|----------------------|-----------|----------------------------------|
| Model catalogue      | GET       | `/models`                        |
| Chat completions     | POST      | `/chat/completions`              |
| Responses API        | POST      | `/responses`                     |
| Audio transcription  | POST      | `/audio/transcriptions`          |
| Audio translation    | POST      | `/audio/translations`            |
| Text-to-speech       | POST      | `/audio/speech`                  |
| Batch jobs           | GET/POST  | `/batches`, `/batches/{batch_id}`|

Additional unsupported Responses API parameters: `previous_response_id`, `store`, `truncation`, `include`, `safety_identifier`,
`prompt_cache_key`.

## 3. Listing Models with the Official SDK

`GroqProviderClient` now delegates to `AsyncGroq.models.list()` so catalogue fetches use the official SDK even when run without a
database configuration. Minimal usage:

```python
import asyncio
from groq import AsyncGroq

async def list_models() -> None:
    client = AsyncGroq()
    response = await client.models.list()
    for model in response.data:
        print(model.id, getattr(model, "context_window", None))

asyncio.run(list_models())
```

Featured catalogues:

- **Production models**: `llama-3.1-8b-instant`, `llama-3.3-70b-versatile`, `openai/gpt-oss-20b`, `openai/gpt-oss-120b`,
  Whisper models, etc.
- **Production systems**: `groq/compound`, `groq/compound-mini`.
- **Preview models**: `meta-llama/llama-4-*`, `moonshotai/kimi-k2-instruct-0905`, `qwen/qwen3-32b`, `playai-tts`, etc.

## 4. Rate Limits & Headers

Groq enforces organisation-level quotas measured in requests per minute/day (RPM/RPD), tokens per minute/day (TPM/TPD), and audio
seconds per hour/day (ASH/ASD). Example limits:

| Model                         | Tier    | RPM | TPM   | Notes                       |
|------------------------------|---------|-----|-------|-----------------------------|
| llama-3.3-70b-versatile      | Free    | 30  | 12K   | 100K tokens/day             |
| openai/gpt-oss-120b          | Free    | 30  | 8K    | 200K tokens/day             |
| moonshotai/kimi-k2-instruct  | Dev    | 60  | 10K   | 300K tokens/day             |
| playai-tts                   | Free    | 10  | 1.2K | Text-to-speech              |
| whisper-large-v3             | Free    | 20  | –     | 7.2K audio seconds / hour   |

Rate-limit headers appear on responses:

```
retry-after: 2
x-ratelimit-limit-requests: 14400
x-ratelimit-remaining-requests: 14370
x-ratelimit-limit-tokens: 18000
x-ratelimit-remaining-tokens: 17997
x-ratelimit-reset-requests: 2m59.56s
x-ratelimit-reset-tokens: 7.66s
```
Handle 429 responses by respecting `retry-after` and backing off.

## 5. Chat Completions Recipes

### Basic completion
```python
from groq import Groq

client = Groq()
completion = client.chat.completions.create(
    model="llama-3.3-70b-versatile",
    messages=[{"role": "user", "content": "Explain the importance of fast language models"}],
)
print(completion.choices[0].message.content)
```

### Streaming
```python
stream = client.chat.completions.create(
    model="llama-3.3-70b-versatile",
    messages=[{"role": "user", "content": "Explain the importance of fast language models"}],
    stream=True,
)
for chunk in stream:
    print(chunk.choices[0].delta.content or "", end="")
```

### Stop sequences & controls
```python
client.chat.completions.create(
    model="llama-3.3-70b-versatile",
    messages=[{"role": "user", "content": "Count to 10. Start with '1, '"}],
    stop=", 6",
    temperature=0.5,
    max_completion_tokens=1024,
)
```

### Async clients & streaming
```python
import asyncio
from groq import AsyncGroq

async def run() -> None:
    client = AsyncGroq()
    chat = await client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": "Explain the importance of fast language models"}],
    )
    print(chat.choices[0].message.content)

    stream = await client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": "Explain the importance of fast language models"}],
        stream=True,
    )
    async for chunk in stream:
        print(chunk.choices[0].delta.content or "", end="")

asyncio.run(run())
```

## 6. Responses API & Built-in Tools

Use the Responses API for multimodal inputs, tool use, or structured outputs.
```python
response = client.responses.create(
    model="llama-3.3-70b-versatile",
    input="Tell me a fun fact about the moon in one sentence.",
)
print(response.output_text)
```

Built-in tools:

- **Code execution** (`code_interpreter`)
- **Browser search** (`browser_search`)
- **Model Context Protocol (MCP)** integrations

Examples:
```python
client.responses.create(
    model="openai/gpt-oss-20b",
    input="What is 1312 x 3333?",
    tool_choice="required",
    tools=[{"type": "code_interpreter", "container": {"type": "auto"}}],
)

client.responses.create(
    model="openai/gpt-oss-20b",
    input="Analyse the current weather in San Francisco.",
    tool_choice="required",
    tools=[{"type": "browser_search"}],
)

client.responses.create(
    model="openai/gpt-oss-120b",
    input="What models are trending on Hugging Face?",
    tools=[{"type": "mcp", "server_label": "Huggingface", "server_url": "https://huggingface.co/mcp"}],
)
```

## 7. Structured Outputs & JSON

Structured Outputs guarantee schema compliance:
```python
from typing import Literal

from groq import Groq
from pydantic import BaseModel


class ProductReview(BaseModel):
    product_name: str
    rating: float
    sentiment: Literal["positive", "negative", "neutral"]
    key_features: list[str]

client = Groq()
response = client.chat.completions.create(
    model="moonshotai/kimi-k2-instruct-0905",
    messages=[
        {"role": "system", "content": "Extract product review information"},
        {"role": "user", "content": "I bought the UltraSound Headphones..."},
    ],
    response_format={
        "type": "json_schema",
        "json_schema": {
            "name": "product_review",
            "schema": ProductReview.model_json_schema(),
        },
    },
)
review = ProductReview.model_validate_json(response.choices[0].message.content)
```

Requirements:

- Every property must be required.
- Set `additionalProperties: false` on every object.
- Union types use `anyOf` with fully specified subschemas.
- Use `$defs`/`$ref` for reusable components; recursive `$ref: "#"` is supported.

If you only need syntactically valid JSON, enable JSON object mode:
```python
client.chat.completions.create(
    model="llama-3.3-70b-versatile",
    messages=[
        {
            "role": "system",
            "content": """Respond only with JSON: {\n  \"sentiment\": "
            "positive|negative|neutral\",\n  \"summary\": "
            "<one sentence>\"\n}""",
        },
        {"role": "user", "content": "I absolutely love this product!"},
    ],
    response_format={"type": "json_object"},
)
```

## 8. Reasoning Workflows

Supported models: `openai/gpt-oss-20b`, `openai/gpt-oss-120b`, `qwen/qwen3-32b`.

Control the returned thinking process:

- `reasoning_format`: `parsed`, `raw`, or `hidden` (non-GPT-OSS models only).
- `include_reasoning`: include/exclude reasoning fields (GPT-OSS models).
- `reasoning_effort`: `none`/`default` for Qwen; `low`/`medium`/`high` for GPT-OSS models.

Example:
```python
from groq import Groq

client = Groq()
stream = client.chat.completions.create(
    model="openai/gpt-oss-20b",
    messages=[{"role": "user", "content": "How many r's are in strawberry?"}],
    temperature=0.6,
    max_completion_tokens=1024,
    top_p=0.95,
    stream=True,
)
for chunk in stream:
    print(chunk.choices[0].delta.content or "", end="")
```

JavaScript example with high reasoning effort:
```javascript
import { Groq } from 'groq-sdk';

const client = new Groq();
const chat = await client.chat.completions.create({
  model: 'openai/gpt-oss-20b',
  reasoning_effort: 'high',
  include_reasoning: true,
  messages: [{ role: 'user', content: 'How do airplanes fly? Be concise.' }],
});
```

Best practices:

- Keep temperature between `0.5`–`0.7` for consistent reasoning.
- Avoid few-shot prompts; place instructions directly in the user message.
- Increase `max_completion_tokens` for complex multi-step answers.

## 9. Speech-to-Text (Transcription & Translation)

Endpoints:

- `POST /audio/transcriptions`
- `POST /audio/translations`

Supported models:

| Model                   | Description                              |
|-------------------------|------------------------------------------|
| `whisper-large-v3`      | Multilingual, highest accuracy           |
| `whisper-large-v3-turbo`| Multilingual, lower cost, faster         |

Constraints:

- File size: 25 MB (free) / 100 MB (dev)
- Minimum billed length: 10 seconds
- Supported types: `flac`, `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `ogg`, `wav`, `webm`
- Response formats: `json`, `verbose_json`, `text`
- Optional `timestamp_granularities`: `segment`, `word`

Transcription example:
```python
import json, os
from groq import Groq

client = Groq()
with open("sample.wav", "rb") as audio:
    transcription = client.audio.transcriptions.create(
        file=audio,
        model="whisper-large-v3-turbo",
        prompt="Specify context or spelling",
        response_format="verbose_json",
        timestamp_granularities=["word", "segment"],
        language="en",
        temperature=0.0,
    )
print(json.dumps(transcription, indent=2, default=str))
```

Translation example:
```python
from groq import Groq

client = Groq()
with open("sample_audio.m4a", "rb") as audio:
    translation = client.audio.translations.create(
        file=("sample_audio.m4a", audio.read()),
        model="whisper-large-v3",
        language="en",
        response_format="json",
        temperature=0.0,
    )
print(translation.text)
```

Metadata fields (from `verbose_json`) help with quality diagnostics:

- `avg_logprob`: confidence (closer to 0 is better)
- `no_speech_prob`: likelihood of silence
- `compression_ratio`: speech cadence indicator
- `start` / `end`: timestamps per segment

## 10. Text-to-Speech

Endpoint: `POST /audio/speech`

Parameters:

- `model`: `playai-tts` or `playai-tts-arabic`
- `input`: text (≤10K characters)
- `voice`: choose from 19 English options (`Fritz-PlayAI`, `Calum-PlayAI`, …) or 4 Arabic voices
- `response_format`: defaults to `wav`

Example:
```python
from groq import Groq

client = Groq()
result = client.audio.speech.create(
    model="playai-tts",
    voice="Fritz-PlayAI",
    input="I love building and shipping new features for our users!",
    response_format="wav",
)
result.write_to_file("speech.wav")
```

## 11. Operational Best Practices

- Use `GroqProviderClient` to list models; it merges per-user credentials with environment fallbacks via the official SDK.
- Prefer `GroqSDKService` helpers when building new chat, responses, or speech features—they manage client lifecycles and logging.
- Monitor rate limit headers and implement exponential back-off on 429 responses.
- For audio workloads, pre-process inputs (e.g., downsample to 16 kHz mono) and consider chunking long files.
- Capture transcription metadata (`avg_logprob`, `no_speech_prob`, `compression_ratio`) to flag low-confidence segments.
- Keep secrets out of source control—store API keys in the database with hashing plus preview masking, or rely on environment
  variables for shared deployments.
- Validate schema outputs when using Structured Outputs; log Groq SDK exceptions with contextual metadata for easier debugging.

Refer back to Groq Cloud documentation for new models, updated limits, and SDK releases.
