Developer quickstart
====================

Take your first steps with the OpenAI API.

The OpenAI API provides a simple interface to state-of-the-art AI [models](/docs/models) for text generation, natural language processing, computer vision, and more. This example generates [text output](/docs/guides/text) from a prompt, as you might using [ChatGPT](https://chatgpt.com).

Generate text from a model

```javascript
import OpenAI from "openai";
const client = new OpenAI();

const response = await client.responses.create({
    model: "gpt-5",
    input: "Write a one-sentence bedtime story about a unicorn."
});

console.log(response.output_text);
```

```python
from openai import OpenAI
client = OpenAI()

response = client.responses.create(
    model="gpt-5",
    input="Write a one-sentence bedtime story about a unicorn."
)

print(response.output_text)
```

```csharp
using OpenAI.Responses;

string key = Environment.GetEnvironmentVariable("OPENAI_API_KEY")!;
OpenAIResponseClient client = new(model: "gpt-5", apiKey: key);

OpenAIResponse response = client.CreateResponse(
    "Write a one-sentence bedtime story about a unicorn."
);

Console.WriteLine(response.GetOutputText());
```

```bash
curl "https://api.openai.com/v1/responses" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
        "model": "gpt-5",
        "input": "Write a one-sentence bedtime story about a unicorn."
    }'
```

[

Configure your development environment

Install and configure an official OpenAI SDK to run the code above.

](/docs/libraries)[

Responses starter app

Start building with the Responses API.

](https://github.com/openai/openai-responses-starter-app)[

Text generation and prompting

Learn more about prompting, message roles, and building conversational apps.

](/docs/guides/text)

Analyze images and files
------------------------

Send image URLs, uploaded files, or PDF documents directly to the model to extract text, classify content, or detect visual elements.

Image URL

Analyze the content of an image

```javascript
import OpenAI from "openai";
const client = new OpenAI();

const response = await client.responses.create({
    model: "gpt-5",
    input: [
        {
            role: "user",
            content: [
                {
                    type: "input_text",
                    text: "What is in this image?",
                },
                {
                    type: "input_image",
                    image_url: "https://openai-documentation.vercel.app/images/cat_and_otter.png",
                },
            ],
        },
    ],
});

console.log(response.output_text);
```

```bash
curl "https://api.openai.com/v1/responses" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
        "model": "gpt-5",
        "input": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": "What is in this image?"
                    },
                    {
                        "type": "input_image",
                        "image_url": "https://openai-documentation.vercel.app/images/cat_and_otter.png"
                    }
                ]
            }
        ]
    }'
```

```python
from openai import OpenAI
client = OpenAI()

response = client.responses.create(
    model="gpt-5",
    input=[
        {
            "role": "user",
            "content": [
                {
                    "type": "input_text",
                    "text": "What teams are playing in this image?",
                },
                {
                    "type": "input_image",
                    "image_url": "https://upload.wikimedia.org/wikipedia/commons/3/3b/LeBron_James_Layup_%28Cleveland_vs_Brooklyn_2018%29.jpg"
                }
            ]
        }
    ]
)

print(response.output_text)
```

```csharp
using OpenAI.Responses;

string key = Environment.GetEnvironmentVariable("OPENAI_API_KEY")!;
OpenAIResponseClient client = new(model: "gpt-5", apiKey: key);

OpenAIResponse response = (OpenAIResponse)client.CreateResponse([
    ResponseItem.CreateUserMessageItem([
        ResponseContentPart.CreateInputTextPart("What is in this image?"),
        ResponseContentPart.CreateInputImagePart(new Uri("https://openai-documentation.vercel.app/images/cat_and_otter.png")),
    ]),
]);

Console.WriteLine(response.GetOutputText());
```

File URL

Use a file URL as input

```bash
curl "https://api.openai.com/v1/responses" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
        "model": "gpt-5",
        "input": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": "Analyze the letter and provide a summary of the key points."
                    },
                    {
                        "type": "input_file",
                        "file_url": "https://www.berkshirehathaway.com/letters/2024ltr.pdf"
                    }
                ]
            }
        ]
    }'
```

```javascript
import OpenAI from "openai";
const client = new OpenAI();

const response = await client.responses.create({
    model: "gpt-5",
    input: [
        {
            role: "user",
            content: [
                {
                    type: "input_text",
                    text: "Analyze the letter and provide a summary of the key points.",
                },
                {
                    type: "input_file",
                    file_url: "https://www.berkshirehathaway.com/letters/2024ltr.pdf",
                },
            ],
        },
    ],
});

console.log(response.output_text);
```

```python
from openai import OpenAI
client = OpenAI()

response = client.responses.create(
    model="gpt-5",
    input=[
        {
            "role": "user",
            "content": [
                {
                    "type": "input_text",
                    "text": "Analyze the letter and provide a summary of the key points.",
                },
                {
                    "type": "input_file",
                    "file_url": "https://www.berkshirehathaway.com/letters/2024ltr.pdf",
                },
            ],
        },
    ]
)

print(response.output_text)
```

```csharp
using OpenAI.Files;
using OpenAI.Responses;

string key = Environment.GetEnvironmentVariable("OPENAI_API_KEY")!;
OpenAIResponseClient client = new(model: "gpt-5", apiKey: key);

using HttpClient http = new();
using Stream stream = await http.GetStreamAsync("https://www.berkshirehathaway.com/letters/2024ltr.pdf");
OpenAIFileClient files = new(key);
OpenAIFile file = files.UploadFile(stream, "2024ltr.pdf", FileUploadPurpose.UserData);

OpenAIResponse response = (OpenAIResponse)client.CreateResponse([
    ResponseItem.CreateUserMessageItem([
        ResponseContentPart.CreateInputTextPart("Analyze the letter and provide a summary of the key points."),
        ResponseContentPart.CreateInputFilePart(file.Id),
    ]),
]);

Console.WriteLine(response.GetOutputText());
```

Upload file

Upload a file and use it as input

```bash
curl https://api.openai.com/v1/files \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -F purpose="user_data" \
    -F file="@draconomicon.pdf"

curl "https://api.openai.com/v1/responses" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
        "model": "gpt-5",
        "input": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_file",
                        "file_id": "file-6F2ksmvXxt4VdoqmHRw6kL"
                    },
                    {
                        "type": "input_text",
                        "text": "What is the first dragon in the book?"
                    }
                ]
            }
        ]
    }'
```

```javascript
import fs from "fs";
import OpenAI from "openai";
const client = new OpenAI();

const file = await client.files.create({
    file: fs.createReadStream("draconomicon.pdf"),
    purpose: "user_data",
});

const response = await client.responses.create({
    model: "gpt-5",
    input: [
        {
            role: "user",
            content: [
                {
                    type: "input_file",
                    file_id: file.id,
                },
                {
                    type: "input_text",
                    text: "What is the first dragon in the book?",
                },
            ],
        },
    ],
});

console.log(response.output_text);
```

```python
from openai import OpenAI
client = OpenAI()

file = client.files.create(
    file=open("draconomicon.pdf", "rb"),
    purpose="user_data"
)

response = client.responses.create(
    model="gpt-5",
    input=[
        {
            "role": "user",
            "content": [
                {
                    "type": "input_file",
                    "file_id": file.id,
                },
                {
                    "type": "input_text",
                    "text": "What is the first dragon in the book?",
                },
            ]
        }
    ]
)

print(response.output_text)
```

```csharp
using OpenAI.Files;
using OpenAI.Responses;

string key = Environment.GetEnvironmentVariable("OPENAI_API_KEY")!;
OpenAIResponseClient client = new(model: "gpt-5", apiKey: key);

OpenAIFileClient files = new(key);
OpenAIFile file = files.UploadFile("draconomicon.pdf", FileUploadPurpose.UserData);

OpenAIResponse response = (OpenAIResponse)client.CreateResponse([
    ResponseItem.CreateUserMessageItem([
        ResponseContentPart.CreateInputFilePart(file.Id),
        ResponseContentPart.CreateInputTextPart("What is the first dragon in the book?"),
    ]),
]);

Console.WriteLine(response.GetOutputText());
```

[

Image inputs guide

Learn to use image inputs to the model and extract meaning from images.

](/docs/guides/images)[

File inputs guide

Learn to use file inputs to the model and extract meaning from documents.

](/docs/guides/pdf-files)

Extend the model with tools
---------------------------

Give the model access to external data and functions by attaching [tools](/docs/guides/tools). Use built-in tools like web search or file search, or define your own for calling APIs, running code, or integrating with third-party systems.

Web search

Use web search in a response

```javascript
import OpenAI from "openai";
const client = new OpenAI();

const response = await client.responses.create({
    model: "gpt-5",
    tools: [
        { type: "web_search" },
    ],
    input: "What was a positive news story from today?",
});

console.log(response.output_text);
```

```python
from openai import OpenAI
client = OpenAI()

response = client.responses.create(
    model="gpt-5",
    tools=[{"type": "web_search"}],
    input="What was a positive news story from today?"
)

print(response.output_text)
```

```bash
curl "https://api.openai.com/v1/responses" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
        "model": "gpt-5",
        "tools": [{"type": "web_search"}],
        "input": "what was a positive news story from today?"
    }'
```

```csharp
using OpenAI.Responses;

string key = Environment.GetEnvironmentVariable("OPENAI_API_KEY")!;
OpenAIResponseClient client = new(model: "gpt-5", apiKey: key);

ResponseCreationOptions options = new();
options.Tools.Add(ResponseTool.CreateWebSearchTool());

OpenAIResponse response = (OpenAIResponse)client.CreateResponse([
    ResponseItem.CreateUserMessageItem([
        ResponseContentPart.CreateInputTextPart("What was a positive news story from today?"),
    ]),
], options);

Console.WriteLine(response.GetOutputText());
```

File search

Search your files in a response

```python
from openai import OpenAI
client = OpenAI()

response = client.responses.create(
    model="gpt-4.1",
    input="What is deep research by OpenAI?",
    tools=[{
        "type": "file_search",
        "vector_store_ids": ["<vector_store_id>"]
    }]
)
print(response)
```

```javascript
import OpenAI from "openai";
const openai = new OpenAI();

const response = await openai.responses.create({
    model: "gpt-4.1",
    input: "What is deep research by OpenAI?",
    tools: [
        {
            type: "file_search",
            vector_store_ids: ["<vector_store_id>"],
        },
    ],
});
console.log(response);
```

```csharp
using OpenAI.Responses;

string key = Environment.GetEnvironmentVariable("OPENAI_API_KEY")!;
OpenAIResponseClient client = new(model: "gpt-5", apiKey: key);

ResponseCreationOptions options = new();
options.Tools.Add(ResponseTool.CreateFileSearchTool(["<vector_store_id>"]));

OpenAIResponse response = (OpenAIResponse)client.CreateResponse([
    ResponseItem.CreateUserMessageItem([
        ResponseContentPart.CreateInputTextPart("What is deep research by OpenAI?"),
    ]),
], options);

Console.WriteLine(response.GetOutputText());
```

Function calling

Call your own function

```javascript
import OpenAI from "openai";
const client = new OpenAI();

const tools = [
    {
        type: "function",
        name: "get_weather",
        description: "Get current temperature for a given location.",
        parameters: {
            type: "object",
            properties: {
                location: {
                    type: "string",
                    description: "City and country e.g. Bogotá, Colombia",
                },
            },
            required: ["location"],
            additionalProperties: false,
        },
        strict: true,
    },
];

const response = await client.responses.create({
    model: "gpt-5",
    input: [
        { role: "user", content: "What is the weather like in Paris today?" },
    ],
    tools,
});

console.log(response.output[0].to_json());
```

```python
from openai import OpenAI

client = OpenAI()

tools = [
    {
        "type": "function",
        "name": "get_weather",
        "description": "Get current temperature for a given location.",
        "parameters": {
            "type": "object",
            "properties": {
                "location": {
                    "type": "string",
                    "description": "City and country e.g. Bogotá, Colombia",
                }
            },
            "required": ["location"],
            "additionalProperties": False,
        },
        "strict": True,
    },
]

response = client.responses.create(
    model="gpt-5",
    input=[
        {"role": "user", "content": "What is the weather like in Paris today?"},
    ],
    tools=tools,
)

print(response.output[0].to_json())
```

```csharp
using System.Text.Json;
using OpenAI.Responses;

string key = Environment.GetEnvironmentVariable("OPENAI_API_KEY")!;
OpenAIResponseClient client = new(model: "gpt-5", apiKey: key);

ResponseCreationOptions options = new();
options.Tools.Add(ResponseTool.CreateFunctionTool(
    functionName: "get_weather",
    functionDescription: "Get current temperature for a given location.",
    functionParameters: BinaryData.FromObjectAsJson(new
    {
        type = "object",
        properties = new
        {
            location = new
            {
                type = "string",
                description = "City and country e.g. Bogotá, Colombia",
            },
        },
        required = new[] { "location" },
        additionalProperties = false,
    }),
    strictModeEnabled: true
));

OpenAIResponse response = (OpenAIResponse)client.CreateResponse([
    ResponseItem.CreateUserMessageItem([
        ResponseContentPart.CreateInputTextPart("What is the weather like in Paris today?"),
    ]),
], options);

Console.WriteLine(JsonSerializer.Serialize(response.OutputItems[0]));
```

```bash
curl -X POST https://api.openai.com/v1/responses \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-5",
    "input": [
      {"role": "user", "content": "What is the weather like in Paris today?"}
    ],
    "tools": [
      {
        "type": "function",
        "name": "get_weather",
        "description": "Get current temperature for a given location.",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {
              "type": "string",
              "description": "City and country e.g. Bogotá, Colombia"
            }
          },
          "required": ["location"],
          "additionalProperties": false
        },
        "strict": true
      }
    ]
  }'
```

Remote MCP

Call a remote MCP server

```bash
curl https://api.openai.com/v1/responses \ 
-H "Content-Type: application/json" \ 
-H "Authorization: Bearer $OPENAI_API_KEY" \ 
-d '{
  "model": "gpt-5",
    "tools": [
      {
        "type": "mcp",
        "server_label": "dmcp",
        "server_description": "A Dungeons and Dragons MCP server to assist with dice rolling.",
        "server_url": "https://dmcp-server.deno.dev/sse",
        "require_approval": "never"
      }
    ],
    "input": "Roll 2d4+1"
  }'
```

```javascript
import OpenAI from "openai";
const client = new OpenAI();

const resp = await client.responses.create({
  model: "gpt-5",
  tools: [
    {
      type: "mcp",
      server_label: "dmcp",
      server_description: "A Dungeons and Dragons MCP server to assist with dice rolling.",
      server_url: "https://dmcp-server.deno.dev/sse",
      require_approval: "never",
    },
  ],
  input: "Roll 2d4+1",
});

console.log(resp.output_text);
```

```python
from openai import OpenAI

client = OpenAI()

resp = client.responses.create(
    model="gpt-5",
    tools=[
        {
            "type": "mcp",
            "server_label": "dmcp",
            "server_description": "A Dungeons and Dragons MCP server to assist with dice rolling.",
            "server_url": "https://dmcp-server.deno.dev/sse",
            "require_approval": "never",
        },
    ],
    input="Roll 2d4+1",
)

print(resp.output_text)
```

```csharp
using OpenAI.Responses;

string key = Environment.GetEnvironmentVariable("OPENAI_API_KEY")!;
OpenAIResponseClient client = new(model: "gpt-5", apiKey: key);

ResponseCreationOptions options = new();
options.Tools.Add(ResponseTool.CreateMcpTool(
    serverLabel: "dmcp",
    serverUri: new Uri("https://dmcp-server.deno.dev/sse"),
    toolCallApprovalPolicy: new McpToolCallApprovalPolicy(GlobalMcpToolCallApprovalPolicy.NeverRequireApproval)
));

OpenAIResponse response = (OpenAIResponse)client.CreateResponse([
    ResponseItem.CreateUserMessageItem([
        ResponseContentPart.CreateInputTextPart("Roll 2d4+1"),
    ]),
], options);

Console.WriteLine(response.GetOutputText());
```

[

Use built-in tools

Learn about powerful built-in tools like web search and file search.

](/docs/guides/tools)[

Function calling guide

Learn to enable the model to call your own custom code.

](/docs/guides/function-calling)

Stream responses and build realtime apps
----------------------------------------

Use server‑sent [streaming events](/docs/guides/streaming-responses) to show results as they’re generated, or the [Realtime API](/docs/guides/realtime) for interactive voice and multimodal apps.

Stream server-sent events from the API

```javascript
import { OpenAI } from "openai";
const client = new OpenAI();

const stream = await client.responses.create({
    model: "gpt-5",
    input: [
        {
            role: "user",
            content: "Say 'double bubble bath' ten times fast.",
        },
    ],
    stream: true,
});

for await (const event of stream) {
    console.log(event);
}
```

```python
from openai import OpenAI
client = OpenAI()

stream = client.responses.create(
    model="gpt-5",
    input=[
        {
            "role": "user",
            "content": "Say 'double bubble bath' ten times fast.",
        },
    ],
    stream=True,
)

for event in stream:
    print(event)
```

```csharp
using OpenAI.Responses;

string key = Environment.GetEnvironmentVariable("OPENAI_API_KEY")!;
OpenAIResponseClient client = new(model: "gpt-5", apiKey: key);

var responses = client.CreateResponseStreamingAsync([
    ResponseItem.CreateUserMessageItem([
        ResponseContentPart.CreateInputTextPart("Say 'double bubble bath' ten times fast."),
    ]),
]);

await foreach (var response in responses)
{
    if (response is StreamingResponseOutputTextDeltaUpdate delta)
    {
        Console.Write(delta.Delta);
    }
}
```

[

Use streaming events

Use server-sent events to stream model responses to users fast.

](/docs/guides/streaming-responses)[

Get started with the Realtime API

Use WebRTC or WebSockets for super fast speech-to-speech AI apps.

](/docs/guides/realtime)

Build agents
------------

Use the OpenAI platform to build [agents](/docs/guides/agents) capable of taking action—like [controlling computers](/docs/guides/tools-computer-use)—on behalf of your users. Use the Agents SDK for [Python](https://openai.github.io/openai-agents-python) or [TypeScript](https://openai.github.io/openai-agents-js) to create orchestration logic on the backend.

Build a language triage agent

```javascript
import { Agent, run } from '@openai/agents';

const spanishAgent = new Agent({
    name: 'Spanish agent',
    instructions: 'You only speak Spanish.',
});

const englishAgent = new Agent({
    name: 'English agent',
    instructions: 'You only speak English',
});

const triageAgent = new Agent({
    name: 'Triage agent',
    instructions:
        'Handoff to the appropriate agent based on the language of the request.',
    handoffs: [spanishAgent, englishAgent],
});

const result = await run(triageAgent, 'Hola, ¿cómo estás?');
console.log(result.finalOutput);
```

```python
from agents import Agent, Runner
import asyncio

spanish_agent = Agent(
    name="Spanish agent",
    instructions="You only speak Spanish.",
)

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
)

triage_agent = Agent(
    name="Triage agent",
    instructions="Handoff to the appropriate agent based on the language of the request.",
    handoffs=[spanish_agent, english_agent],
)

async def main():
    result = await Runner.run(triage_agent, input="Hola, ¿cómo estás?")
    print(result.final_output)

if __name__ == "__main__":
    asyncio.run(main())
```

[

Build agents that can take action

Learn how to use the OpenAI platform to build powerful, capable AI agents.

](/docs/guides/agents)


# OpenAI Platform Guide (Agent-Ready, 2025)

> Source: Official OpenAI docs. This file is written so an autonomous agent can implement features endâ€‘toâ€‘end without guesswork.

## 0) Base, Auth, SDKs

- **Base URL**: `https://api.openai.com/v1`
- **Auth header**: `Authorization: Bearer $OPENAI_API_KEY`
- **SDKs**: Official Python and Node libraries; use raw HTTPS for anything not yet wrapped.

---

## 1) Responses API (primary)

Create outputs from text, images, tools, and structured I/O.

**Endpoint**: `POST /v1/responses`

### Minimal text
```bash
curl https://api.openai.com/v1/responses   -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json"   -d '{
    "model":"gpt-4o-mini",
    "input":"Explain dropout like I am new to ML."
  }'
```

### Tool calling (function calling)
- Define tools with `type:"function"`, `function:{ name, description, parameters(JSON Schema) }`.
- Set `parallel_tool_calls:true` to allow concurrent calls.
- The model yields `output[...].type:"tool_call"` with `name` and `arguments` (stringified JSON).
- You must execute the tool, then send results back using a **follow-up** request that includes a new `input` item of type `tool_result` with the same `tool_call_id`.

```jsonc
{
  "model":"gpt-4o",
  "input":[
    {"role":"user","content":[{"type":"text","text":"Weather in Surat now"}]}
  ],
  "tools":[{
    "type":"function",
    "function":{
      "name":"get_weather",
      "description":"Read current weather by city",
      "parameters":{
        "type":"object",
        "properties":{"city":{"type":"string"}},
        "required":["city"]
      }
    }
  }],
  "parallel_tool_calls": true
}
```

### Structured output
Use `response_format: {"type":"json_schema","json_schema":{...}}` to force well-formed JSON. The model returns a JSON object in `output_text` and JSON content in the item with `type:"output_text"`.

### Multimodal input
Attach images via `{"type":"input_image","image_url":{ "url":"https://..." }}` or with uploaded files (see Uploads). Combine with text parts in the same `input` array item.

### Streaming
Add `"stream": true` to receive **SSE** events. Parse chunk types (e.g., `response.output_text.delta`, `response.tool_call.delta`, `response.completed`, `response.error`) and stop on `response.completed` or `response.error`.

---

## 2) Chat Completions (legacy)

- **Endpoint**: `POST /v1/chat/completions`
- Still supported, but new features and tools land in **Responses** first. Prefer **Responses** for new work.

---

## 3) Images

Two paths:
1) **Images API** (`/v1/images/generations`, edits, variations) for direct image outputs.
2) **Responses API with image tool** for unified orchestration (image outputs as part of a response).

Minimal (Images API):
```bash
curl https://api.openai.com/v1/images/generations   -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json"   -d '{"model":"gpt-image-1","prompt":"a low-poly fox"}'
```

Within Responses:
```jsonc
{
  "model":"gpt-4o",
  "input":[{"role":"user","content":[{"type":"text","text":"Generate a logo: lowâ€‘poly fox"}]}],
  "tools":[{"type":"image_generation"}]
}
```

Returned image data is provided as URLs or base64 depending on your request options.

---

## 4) Audio

### 4.1 Speech-to-text (transcription/translation)
**Endpoint**: `POST /v1/audio/transcriptions` or `/v1/audio/translations`  
**Content-Type**: `multipart/form-data` with `file`, `model`.

```bash
curl https://api.openai.com/v1/audio/transcriptions   -H "Authorization: Bearer $OPENAI_API_KEY"   -H "Content-Type: multipart/form-data"   -F file="@sample.m4a" -F model="whisper-1"
```

### 4.2 Text-to-Speech
**Endpoint**: `POST /v1/audio/speech` with `model`, `input`, and optional `voice`, `format`.

---

## 5) Models

- List models: `GET /v1/models`
- Retrieve: `GET /v1/models/{id}`
- Use the **Models** docs to pick the right snapshot or alias for text, vision, or tool-heavy tasks.

---

## 6) Files and Uploads (chunked)

There are two related surfaces:
- **Files API** for small uploads and general file handles.
- **Uploads API** for **chunked** multiâ€‘part uploads and large files. Flow:
  1. `POST /v1/uploads` to create an upload (get `id`, `url`).
  2. `POST /v1/uploads/{id}/parts` to add parts. Repeat for each chunk; provide `index` and `content` (binary).
  3. `POST /v1/uploads/{id}/complete` to finalize; you receive file ids suitable for use with tools (e.g., file search, image, audio).

Attach uploaded files to vector stores, use in Responses with `input_image`, or with assistants/agents for retrieval.

---

## 7) Vector Stores and File Search

- Create a vector store, upload files, and attach the store to an agent or a Responses call that uses the `file_search` tool.
- Current limits often allow attaching up to **two vector stores** simultaneously.
- Retrieval is automatic; the model emits citations or chunks depending on configuration.

---

## 8) Agents and Tools

- Agents are orchestrations over the Responses API that use builtâ€‘in tools (web search, file search, code interpreter) and **function calling** to your tools or remote **MCP connectors**.
- In pure HTTP, this is just the loop: send input â†’ read tool calls â†’ execute â†’ send tool results â†’ repeat until `response.completed`.

### Tool result item shape (followâ€‘up request)
```jsonc
{
  "type": "tool_result",
  "tool_call_id": "call_abc123",
  "output": [
    {"type":"output_text","text":"Sunny, 33Â°C"}
  ]
}
```

---

## 9) Batch API

- Submit many requests asynchronously at lower cost and higher rate limits.
- Create a **JSONL** file of requests, upload it, then `POST /v1/batches` targeting the desired endpoint (e.g., `/v1/responses` or `/v1/chat/completions`, depending on current support).
- Poll batch status; download output file when complete.

---

## 10) Fineâ€‘tuning

- Create jobs with base model and training file; monitor status; use the returned fineâ€‘tuned model id.
- Use when you need style or task adaptation beyond prompt+tools+RAG.

---

## 11) Realtime API

Two transport options:
- **WebRTC**: lowâ€‘latency audio and duplex text/JSON; best for voice bots and live UIs.
- **Serverâ€‘sent events / WebSocket** via HTTP: simpler server setups, textâ€‘first.

Core flow: open a session, stream audio/text in, receive incremental events (`response.delta`, `input_audio_buffer.*`, `response.completed`). SIP ingress is supported to route phone calls directly to a realtime model.

---

## 12) Production notes

- Prefer **Responses** over Chat Completions for new builds.
- Use **structured outputs** with JSON Schema for agentâ€‘safe parsing.
- Set conservative **tool schemas** and strict validation on your side.
- Add **timeouts**, **retry with backoff**, and observe **rateâ€‘limit headers**.
- For privacy, scope API keys per service; rotate regularly.
- Monitor cost: pick smaller models for routing, larger for heavy synthesis. Batch lowâ€‘priority work.

---

## 13) Agent skeletons

### Node (Responses + tools + streaming)
```js
import OpenAI from "openai";
const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

const tools = [{
  type: "function",
  function: {
    name: "get_weather",
    description: "Weather by city",
    parameters: {
      type: "object",
      properties: { city: { type: "string" } },
      required: ["city"]
    }
  }
}];

function sse(url, opts, onEvent) {
  const ctrl = new AbortController();
  fetch(url, { ...opts, signal: ctrl.signal }).then(async r => {
    const dec = new TextDecoder();
    const reader = r.body.getReader();
    let buf = "";
    for (;;) {
      const { value, done } = await reader.read();
      if (done) break;
      buf += dec.decode(value, { stream: true });
      for (const line of buf.split("\n\n")) {
        if (!line.startsWith("data:")) continue;
        const payload = JSON.parse(line.slice(5).trim());
        onEvent(payload);
      }
    }
  });
  return () => ctrl.abort();
}

export async function run(query) {
  const body = {
    model: "gpt-4o",
    input: [{ role: "user", content: [{ type: "text", text: query }] }],
    tools,
    parallel_tool_calls: true,
    stream: true
  };

  const toolResults = {};
  await new Promise(resolve => {
    sse("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(body)
    }, async ev => {
      if (ev.type === "response.output_text.delta") process.stdout.write(ev.delta);
      if (ev.type === "response.tool_call.delta") {
        const d = ev.delta;
        if (d.name === "get_weather" && d.arguments) {
          const args = JSON.parse(d.arguments || "{}");
          const out = { tempC: 33, city: args.city || "Surat" }; // stub
          toolResults[d.id] = out;
        }
      }
      if (ev.type === "response.completed") resolve();
    });
  });

  // Send tool results if any
  const followUp = {
    model: "gpt-4o",
    input: [
      { role: "system", content: [{ type: "text", text: "Cite sources if available." }] },
      *[
        ...Object.entries(toolResults).map(([id, out]) => ({
          role: "tool",
          content: [{
            type: "tool_result",
            tool_call_id: id,
            output: [{ type: "output_text", text: JSON.stringify(out) }]
          }]
        }))
      ]
    ]
  };
  const r2 = await client.responses.create(followUp);
  return r2.output_text;
}
```

### Python (batch-friendly)
```python
import os, json, time, requests

BASE = "https://api.openai.com/v1"
HEADERS = {"Authorization": f"Bearer {os.environ['OPENAI_API_KEY']}"}

def response(input_text):
  data = {"model":"gpt-4o-mini","input": input_text}
  r = requests.post(f"{BASE}/responses", headers={**HEADERS,"Content-Type":"application/json"}, data=json.dumps(data), timeout=60)
  r.raise_for_status()
  return r.json()

def upload_jsonl(path):
  # Files API small upload for batch
  with open(path,"rb") as f:
    r = requests.post(f"{BASE}/files", headers=HEADERS, files={"file":(path,f)}, data={"purpose":"batch"})
  r.raise_for_status()
  return r.json()["id"]
```

---

## 14) Error model

- Standard JSON problem objects with `error.type`, `error.message`, and sometimes `error.param`.
- Handle 400 (validation), 401 (auth), 429 (rate limit), 5xx (retry with jitter).

---

## 15) Pricing and limits

- Costs vary by model, I/O type (text/image/audio), and processing tier (flex/standard/priority). Batch discounts apply. Always consult the pricing table before shipping.

---

This is the stable skeleton you need. Plug in models and tools per your use case, wire the tool loop, and you have a productionâ€‘ready agent.
